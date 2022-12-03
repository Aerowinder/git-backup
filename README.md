# git-backup

Automatically backup your synced git repositories to another folder. Can optionally prune old backups. Sync this repo to your git folder like any other repo. The script will get the parent folder so you don't need to move any files.<br><br><br>

**Make the following modifications to the file:**<br><br>

<code>$keepbackup = int</code><br>
Number of backups to keep, default 24. If script runs once per week, this is 6 months worth of backups before any pruning occurs. Once this number is met, the oldest backup will be pruned. Set to arbitrarily large number to disable pruning.<br><br>


**Backup-Git**<br>
<code>$repo_list = "x","y","z"</code><br>
Add a repo to the backup list. These are explicitly named, so no unintentional backups occur. The hidden .git folder will be ignored.<br><br>

**Backup-Git-7za**<br>
<code>$ht.Add('repo-name", '-xr!.git')</code><br>
Add a repo to the backup list. These are explicitly named, so no unintentional backups occur. The hashtable value tells 7za to ignore the .git folder.
