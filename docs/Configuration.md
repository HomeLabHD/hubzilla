# Configuration

The image ships **php-fpm on port 9000** and nothing else. Hubzilla itself is configured by
`.htconfig.php` and by settings it stores in its own database — not by environment variables.
The environment covers only what has to stay out of the config file and out of image layers.

## Environment variables

Read by the `sendmail` shim at send time. Hubzilla sends mail through PHP's `mail()`, so
without a relay, registration, password resets and every notification silently fail.

| Variable | Default | |
|----------|---------|-|
| `SMTP_USER` | — | **Required.** Relay username |
| `SMTP_PASSWORD` | — | **Required.** Read from the environment on each send; never written to disk |
| `SMTP_HOST` | `smtp.gmail.com` | Relay host |
| `SMTP_PORT` | `587` | Relay port — STARTTLS is always on |
| `SMTP_FROM` | `$SMTP_USER` | Envelope sender |

## Database

MySQL/MariaDB or PostgreSQL, created and reachable before first boot. Credentials and the
driver selection live in `.htconfig.php`.

Supplying a `.htconfig.php` **skips Hubzilla's installer**, and the installer is what creates
the schema. On a fresh database, load it once:

```bash
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < install/schema_mysql.sql
```

Guard that on an existing-table check — the file uses plain `CREATE TABLE`, so a second run
fails rather than no-ops.

## Writable paths

Code is owned by `root` and never written to at runtime, so the root filesystem can be
mounted read-only. Three paths are genuinely written and must be mounts:

| Path | |
|------|-|
| `/var/www/html/store` | Uploads, photos, attachments, cloud files — persistent, and the one that grows |
| `/var/www/html/view/tpl/smarty3` | Compiled templates — regenerated on demand, may be ephemeral |
| `/var/www/html/.htconfig.php` | Site configuration — mount read-only from a secret |
| `/tmp` | PHP session and upload scratch |

## Web server

Hubzilla reads the requested path from a **`q` query parameter**, per its own `.htaccess`.
Rewriting to `index.php` without carrying the path is the single most common way to break a
deployment: every routed request renders the home page, which looks like a stylesheet problem
but is actually breaking channels, profiles, `.well-known` discovery and ActivityPub delivery
at the same time.

```nginx
location ^~ /store/ { deny all; return 404; }

location / {
    try_files $uri $uri/ /index.php?q=$uri&$args;
}

location ~ \.php$ {
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

`client_max_body_size` must be at least the `upload_max_filesize` compiled into the image
(100M) or large uploads are rejected before PHP sees them.

## Background jobs

Hubzilla's delivery queue, polling and maintenance run from a cron daemon. Nothing federates
outward without it — posts sit in `workerq` and remote hubs never hear about them.

```bash
cd /var/www/html && php Zotlabs/Daemon/Master.php Cron
```

Run it on a schedule (every 10 minutes upstream; more often for a snappier queue) from a
container that mounts the same `store/` and `.htconfig.php`. Runs must not overlap — a
second invocation while the first still holds the queue produces lock-wait timeouts on
`workerq`.

## Federation

The **`pubcrawl`** addon provides ActivityPub and ships in this image, but addons are enabled
per-hub in the admin panel; Hubzilla speaks Zot only until it is turned on.

The domain in `.htconfig.php` is **permanent** once the hub has federated. Remote hubs key
identities to it, so changing it later strands every connection.
