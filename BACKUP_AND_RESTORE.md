# Backup and restore

Plant-it Enhanced includes a portable full-stack backup helper. It captures the MySQL database,
uploaded images, image metadata, user accounts, plant profiles, reminders, diaries, synchronized
hike sessions, and synchronized field observations. API keys and passwords are intentionally not
copied into the archive; keep `.env` in your password manager.

Pending offline field drafts live in the browser or mobile device until they synchronize. They are
not part of a server backup. Open **Trail Journal** and confirm that no draft is pending or failed
before clearing browser data, replacing a device, or relying on a server archive for those finds.

## Create a backup

Run from the repository directory that contains your active Compose file and `.env`:

```bash
COMPOSE_FILE="$PWD/compose.example.yaml" \
DATA_DIRECTORY="$PWD/data" \
./scripts/backup.sh
```

The regular application database account is used with `--no-tablespaces`, so it does not need the
MySQL `PROCESS` privilege. Archives are written to `./backups` and are retained for 30 days by
default. Override `BACKUP_DIRECTORY` and `BACKUP_RETENTION_DAYS` when needed.

For a daily scheduled backup on the NAS, add the following command to its task scheduler or cron.
Use absolute paths and run it as the same account that manages Docker:

```cron
15 3 * * * COMPOSE_FILE=/volume1/docker/Dockge/stacks/plantit/compose.yaml ENV_FILE=/volume1/docker/Dockge/stacks/plantit/.env DATA_DIRECTORY=/volume1/docker/Dockge/stacks/plantit/data BACKUP_DIRECTORY=/volume1/docker/plantit-backups /volume1/docker/Dockge/stacks/plantit/source/scripts/backup.sh
```

Copy at least one recent archive to a different device. A backup stored only on the same NAS is not
protection from disk or pool failure.

## Restore

Restore replaces the active database and uploaded-image directory. The script requires an explicit
confirmation flag, stops only the Plant-it server, preserves the old upload directory beside the
restored one, verifies archive checksums, and checks the restored database before finishing.

```bash
COMPOSE_FILE="$PWD/compose.example.yaml" \
DATA_DIRECTORY="$PWD/data" \
./scripts/restore.sh --confirm-replace-all-data \
  /absolute/path/to/plant-it-20260717-031500.tar.gz
```

Test a restore periodically on a disposable stack. An untested archive is only a hopeful backup.

After a restore, sign in and verify **My Green Friends**, **Today**, and **Trail Journal**, then check
that uploaded plant and observation photos open normally.
