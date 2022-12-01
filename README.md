# git-backup

Automatically backup (and optionally prune) your synced git repositories. Sync this repo to your git folder like any other repo. It will get the parent folder so you don't need to move any files.

Make the following modifications to the file:<br>
<code>$keepbackup = int</code> - Number of backups to keep, default 24. If script runs once per week, this is 6 months worth of backups before any pruning occurs. Once this number is met, the oldest backup will be pruned. Set to arbitrarily large number to disable pruning.<br>
<code>$ht.Add('repo-name", '-xr!.git')</code> - Add a repo to the backup list. These are explicitly named, so no unintentional backups occur. the hashtable value tells 7zip to ignore the .git folder.
