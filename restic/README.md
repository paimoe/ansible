# Restic Backup — Automated

A wrapper script around `restic backup` that targets one or more repos
by name.  Repo paths are defined inside `restic-backup.sh`.

## Schedule

The file `crontab.txt` contains a cron entry that runs the backup **every
6 hours** against the `2tb` repo.

### Activate the crontab

1. Open your user crontab editor:

   ```bash
   crontab -e
   ```

2. Copy the contents of `crontab.txt` into the editor and save.

Alternatively, install it in one shot:

```bash
crontab crontab.txt
```

> **Caution:** `crontab crontab.txt` **replaces** your existing crontab.
> If you already have cron jobs, use `crontab -e` and paste the line in
> manually instead.

### Verify

List your active cron jobs:

```bash
crontab -l
```

Check the log after the next scheduled run:

```bash
tail -f restic-backup.log
```

## Environment

The script loads `RESTIC_PASSWORD` from the `.env` file in the same
directory — no extra setup needed.
