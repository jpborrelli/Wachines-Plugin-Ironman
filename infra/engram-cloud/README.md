# Engram Cloud

Fly app for the Wachines shared Engram memory server.

## App

- App: `wachines-engram-cloud`
- URL: `https://wachines-engram-cloud.fly.dev`
- Region: `sjc`
- Allowed projects: `backoffice`, `reportegrass`, `gestionganadera`, `wachines-brain-server`

## Required secrets

- `ENGRAM_DATABASE_URL`: Postgres DSN, set by `fly postgres attach`.
- `ENGRAM_CLOUD_TOKEN`: shared bearer token for team sync clients.
- `ENGRAM_JWT_SECRET`: non-default JWT secret required by authenticated cloud serve.
- `ENGRAM_CLOUD_ADMIN`: optional dashboard/admin token.

Never commit token values.

### Generating / rotating `ENGRAM_CLOUD_TOKEN`

This is the single token every developer uses to sync memories. Generate a strong random value:

```bash
openssl rand -hex 32
```

Set it on the Fly app:

```bash
fly secrets set ENGRAM_CLOUD_TOKEN=<token> --app wachines-engram-cloud
```

Then share the token with the team over a secure channel (1Password, Signal, etc.). Each developer exports it before running `setup-dev.sh` or any `engram sync --cloud` command.

If you suspect the token leaked, rotate it with the same steps; clients using the old token will stop syncing until they update.

## Deploy

```bash
cd infra/engram-cloud
fly deploy
```

## Client setup

Each developer sets:

```bash
export ENGRAM_CLOUD_SERVER="https://wachines-engram-cloud.fly.dev"
export ENGRAM_CLOUD_TOKEN="<team token>"
engram cloud config --server "$ENGRAM_CLOUD_SERVER"
engram cloud enroll backoffice
engram sync --cloud --project backoffice
```

The shared bootstrap in `bin/setup-dev.sh` performs the enroll/sync step for the known repos when
both env vars are present.
