# Restic Backup — Automated

A wrapper script around `restic backup` that targets one or more repos
by name.  Repo paths are defined inside `restic-backup.sh`.

## Schedule

The file `crontab` contains a cron entry that runs the backup **every
6 hours** against the `2tb` repo.

### Activate the crontab

Run the install script to symlink `crontab` into `/etc/cron.d/`:

```bash
sudo ./install-cron.sh
```

The entry is written to `/etc/cron.d/restic-backup` and cron will pick it
up automatically.

> **Note:** `crontab` includes a username field (`paimoe`) because
> `/etc/cron.d/` entries require it.  If you prefer a user crontab instead,
> remove the username and use `crontab -e`.

### Verify

Confirm the cron.d entry is in place:

```bash
cat /etc/cron.d/restic-backup
```

Check the log after the next scheduled run:

```bash
tail -f restic-backup.log
```

   ```bash
   crontab -e
   ```

Restart cron with `sudo systemctl restart cron`.

## Environment

The script loads `RESTIC_PASSWORD` from the `.env` file in the same
directory.
