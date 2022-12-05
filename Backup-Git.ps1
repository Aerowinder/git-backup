#User customizable variables#
[string]$dir_parent = (Split-Path -Parent $PSScriptRoot) + '\' #Get parent directory of script root directory.
$dir_backup = $dir_parent + '_backup\'
$dir_log = $dir_backup + '_logs'
$file_log = $dir_log + '\' + (Get-Date -Format yyyy-MM-dd) + '.txt'
$keepbackup = 24
#############################

# Error: Folder not found. 
# Folder: \\10.10.2.1\Gitdns-blackhole

if (-Not(Test-Path -Path $dir_log)) {Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('Log folder not found (' + $dir_log + '), script will terminate.','Git Backup Prune Script','Ok','Error'); break} #If $logdir does not exist, show messagebox then terminate script.

function LogWrite{ # We don't need to verify $dir_log exists, since the script will exit before it gets to this point if it doesn't exist.
    param([string]$message)

    $time = Get-Date -Format HH:mm:ss
    Add-Content $file_log -Value ($time + ':   ' + $message + "`n")
}

$repo_backup = "budget-pdq-deploy","code-dump","credential-manager","dns-blackhole","git-backup","mikrotik-tools","scheduled-task","smartvu-map","vm-backup-prune"

foreach ($entry in $repo_backup) {
    $path_live = $dir_parent + $entry
    $path_backup = $dir_backup + $entry

    if (-Not(Test-Path -Path $path_live)) {LogWrite ("Error: Folder not found. `n            Folder: " + $path_live); continue} #If live path does not exist, write log file and skip to next iteration of loop.
    New-Item -Path ($path_backup) -ItemType Directory -Force | Out-Null #Create backup folder if it doesn't exist.

    #If you backup before you prune, you will always have a new backup to check against, rendering the age check obsolete. The point of the age check is to verify that the script is running as it should.
    #If we take the requested backup retention - 1, we can effectively age check the older backups, then create a new one, matching $keepbackup.
#####PRUNE#####
    $files = Get-ChildItem -Path ($path_backup + '\*') -Include ($entry + '*.zip') #Grab complete list of files in the subfolder.

    if (-Not $null -eq $files) { #At least one backup exists for this entry.
        $newestfile = $files | Sort-Object -Property Name -Descending | Select-Object -First 1 #Select newest file from the list of files in the subfolder.
        if (Test-Path $newestfile -OlderThan (Get-Date).AddDays(-7)) {LogWrite ("Error: No new backups found. `n            Folder: " + $path_backup); continue} #If newest log file is older than 7 days, write log file and skip to next iteration of loop.
    }

    if ($files.Count -gt $keepbackup - 1) { #Since we are pruning backups first, we must subtract 1 from $keepbackup. Otherwise, we would end up with $keepbackup + 1 total backups.
        $prune = $files | Sort-Object -Property Name -Descending | Select-Object -Last ($files.Count - $keepbackup - 1) #Must check file count before processing as a negative number results in exception. Subtracting 1 because pruning happens before backup.
        $prune | ForEach-Object { Remove-Item $_ }#-WhatIf # WhatIf is for testing, dry run.
    }
    
    $files = $null #Clearing these variables (resetting to $null) should not be necessary, it is here just in case.
    $prune = $null #There could be an edge case where these variables don't get emptied upon error, and could consequently fail to fire off an email.

#####BACKUP#####
    $dt = Get-Date -Format yyyy.MM.dd_HH.mm.ss
    $dest = $path_backup + '\' + $entry + '_' + $dt + '.zip'
    $src = $dir_parent + $entry
    Compress-Archive -Path $src -DestinationPath $dest #Compress-Archive does not pull hidden files, .git will be excluded automatically.
}

if (Test-Path $file_log) {Invoke-Item $file_log} #If log file exists, open it up and leave it on screen.

#Changelog
#2022-12-01 - AS - v1, First release. Refactored VM Backup prune script for Git backup/prune.
#2022-12-02 - AS - v2, added vm-backup-prune, scheduled-task, budget-pdq-deploy, credential-manager to backup list. Added _ to backup path for better file explorer sorting
#2022-12-03 - AS - v3, removed 7za dependency. Switched hash table to array since we don't need to store key/value pairs anymore.
