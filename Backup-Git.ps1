#User customizable variables#
[string]$dir_parent = Split-Path -Parent $PSScriptRoot #Get parent directory of script root directory.
$dir_backup = $dir_parent + 'backup\'
$file_7za =  $dir_backup + '7za\7za.exe'
$args_7za = 'a -mx=9 -ms=on -ssw'
$dir_log = $dir_backup + '_logs'
$file_log = $dir_log + '\' + (Get-Date -Format yyyy-MM-dd) + '.txt'
$keepbackup = 24
#############################

if (-Not(Test-Path -Path $dir_log)) {Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('Log folder not found (' + $dir_log + '), script will terminate.','Git Backup Prune Script','Ok','Error'); break} #If $logdir does not exist, show messagebox then terminate script.

function LogWrite{ # We don't need to verify $dir_log exists, since the script will exit before it gets to this point if it doesn't exist.
    param([string]$message)

    $time = Get-Date -Format HH:mm:ss
    Add-Content $file_log -Value ($time + ':   ' + $message + "`n")
}

$ht = [ordered]@{} # Key = Mask, Value = Subfolder; hashtable is ordered mostly for log display purposes, technically doesn't matter.
$ht.Add('dns-blackhole', '-xr!.git') #Folder name, extra 7za switches. -xr!.git excludes entire .git folder.
$ht.Add('git-backup', '-xr!.git')

foreach ($entry in $ht.GetEnumerator()) {
    $path_live = $dir_parent + $entry.Name
    $path_backup = $dir_backup + $entry.Name

    if (-Not(Test-Path -Path $path_live)) {LogWrite ("Error: Folder not found. `n            Folder: " + $path_live); continue} #If live path does not exist, write log file and skip to next iteration of loop.
    New-Item -Path ($path_backup) -ItemType Directory -Force | Out-Null #Create backup folder if it doesn't exist.

    #If you backup before you prune, you will always have a new backup to check against, rendering the age check obsolete. The point of the age check is to verify that the script is running as it should.
    #If we take the requested backup retention - 1, we can effectively age check the older backups, then create a new one, matching $keepbackup.
#####PRUNE#####
    $files = Get-ChildItem -Path ($path_backup + '\*') -Include ($entry.Name + '*.7z') #Grab complete list of files in the subfolder.

    if (-Not $null -eq $files) { #At least one backup exists for this entry.
        $newestfile = $files | Sort-Object -Property Name -Descending | Select-Object -First 1 #Select newest file from the list of files in the subfolder.
        if (Test-Path $newestfile -OlderThan (Get-Date).AddDays(-7)) {LogWrite ("Error: No new backups found. `n            Folder: " + $path_backup); continue} #If newest log file is older than 7 days, write log file and skip to next iteration of loop.
    }

    if ($files.Count -gt $keepbackup - 1) { #Since we are pruning backups first, we must subtract 1 from $keepbackup. Otherwise, we would end up with $keepbackup + 1 total backups.
        $prune = $files | Sort-Object -Property Name -Descending | Select-Object -Last ($files.Count - $keepbackup) #Must check file count before processing as a negative number results in exception.
        $prune | ForEach-Object { Remove-Item $_ }#-WhatIf # WhatIf is for testing, dry run.
    }
    
    $files = $null #Clearing these variables (resetting to $null) should not be necessary, it is here just in case.
    $prune = $null #There could be an edge case where these variables don't get emptied upon error, and could consequently fail to fire off an email.

#####BACKUP#####
    $dt = Get-Date -Format yyyy.MM.dd_HH.mm.ss
    $dest = $path_backup + '\' + $entry.Name + '_' + $dt + '.7z'
    $src = $dir_parent + $entry.Name
    Start-Process -Wait -FilePath "$file_7za" -ArgumentList $args_7za,$entry.Value,$dest,$src
}

if (Test-Path $file_log) {Invoke-Item $file_log} #If log file exists, open it up and leave it on screen.

#Changelog
#2022-12-01 - AS - v1, First release. Refactored VM Backup prune script for Git backup/prune.
