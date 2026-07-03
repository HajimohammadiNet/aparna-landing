# Aparna Landing

Persian static landing page for Aparna, the apartment charge management bot.

## Local preview

```sh
python3 -m http.server 4173
```

Then open `http://localhost:4173`.

## Deployment

Production static files are deployed to:

```text
/opt/apartment-bot-prod/web/landing
```

The `apartment-bot` production Caddy container serves that directory at the root domain and keeps `/webhook` proxied to the bot.

Deploy from a trusted machine with SSH access:

```sh
deploy/manual-deploy.sh prod
```

Stage is also supported:

```sh
deploy/manual-deploy.sh stage
```

Environment overrides:

- `APARNA_SSH_TARGET`: SSH host, defaults to `aparna-srv-01`
- `STAGE_APP_DIR`: defaults to `/opt/apartment-bot-stage`
- `PROD_APP_DIR`: defaults to `/opt/apartment-bot-prod`
- `LANDING_TARGET_DIR`: explicit remote target directory override
