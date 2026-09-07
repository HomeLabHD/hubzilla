# 🛸 hubzilla

A **rootless** container image for [Hubzilla](https://hubzilla.org/) — the federated social platform built around **nomadic identity**: a channel is a portable, cryptographically-owned thing that can live on several hubs at once, so an account outlives the server it was created on. Hubzilla speaks its native **Zot** protocol *and* **ActivityPub** (Mastodon, Pixelfed, Lemmy, …), and puts an **access-control list on every object** — each post, photo, file, wiki page and event. Core and the official addon set are cloned at a **pinned upstream ref at build time** and baked in.

<!-- sf:project:start -->
<!-- sf:project:end -->
<!-- sf:badges:start -->
<!-- sf:badges:end -->
<!-- sf:image:start -->
<!-- sf:image:end -->

### Documentation

| Topic | |
|-------|-|
| [Configuration](docs/Configuration.md) | Environment reference, writable paths, database, and the web-server rewrite Hubzilla requires |

### What Hubzilla is

|                            |                                                                                                      |
| -------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Nomadic identity**       | Clone a channel to another hub — both copies stay in sync and either can serve it. Losing a hub does not lose the identity, the connections, or the posts |
| **Permissions per object** | Every item carries its own ACL, addressable to individuals, privacy groups or the public — not a fixed public/followers/DM ladder |
| **Two federation stacks**  | Zot natively; ActivityPub through the bundled `pubcrawl` addon, so the same channel is reachable from Mastodon and friends |
| **Single sign-on, remote** | OpenWebAuth recognises visitors from other Zot hubs and grants them exactly what their ACL allows — no account needed here |
| **More than a timeline**   | Channels, forums, WebDAV cloud storage, wikis, published webpages, CalDAV calendars and events — one app, one permission model |
| **Curation-friendly**      | Registration policy, per-channel permission roles and connection filters make a small, deliberately-scoped hub practical to run |

### What this image adds

|                        |                                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Pinned build**       | Core + addons are fetched at a fixed ref during `docker build`. The running version is the tag you deployed, not whatever upstream `master` was when the pod last restarted |
| **Rootless**           | Runs as `www-data` with a read-only root filesystem — the only writable paths are mounts               |
| **Mail that leaves**   | An `msmtp` `sendmail` shim reads `SMTP_*` from the environment at send time, so registration, password resets and notifications work and no relay password lands in a layer |
| **php-fpm only**       | No bundled web server, no supervisor — front it with your own nginx/Caddy and scale the pod, not the process tree |

## Image contents

<details>
<summary>Base image &amp; installed components (click to expand)</summary>

Base Image:
<!-- sf:contents-base:start -->
<!-- sf:contents-base:end -->

PHP extensions: `gd` (freetype + jpeg), `pdo`, `pdo_mysql`, `zip`, `exif`, `intl`, `bcmath`, `gmp`, `imagick`

Packages (apt): `imagemagick`, `msmtp`, `libzip4`

Pinned components — see [`components.json`](components.json):

| Component | Source | Ref |
|-----------|--------|-----|
| core | [hubzilla/core](https://framagit.org/hubzilla/core) via [HomeLabHD mirror](https://github.com/HomeLabHD/hubzilla-core) | `11.4` |
| addons | [hubzilla/addons](https://framagit.org/hubzilla/addons) via [HomeLabHD mirror](https://github.com/HomeLabHD/hubzilla-addons) | `11.4` |

</details>

---

## Installation

Pull the image (**ghcr** primary, Docker Hub mirror):

```bash
docker pull ghcr.io/homelabhd/hubzilla:latest
# or
docker pull docker.io/hlhd/hubzilla:latest
```

Or build it — the refs are required, there is no floating default:

```bash
git clone https://github.com/HomeLabHD/hubzilla
cd hubzilla
docker build -t hlhd/hubzilla \
  --build-arg HUBZILLA_REF=11.4 \
  --build-arg ADDONS_REF=11.4 .
```

Hubzilla needs a MySQL/MariaDB or PostgreSQL database, a mounted `.htconfig.php`, and persistent storage for `store/`. The container serves **php-fpm on 9000** — put nginx in front of it, and note that Hubzilla routes on a `q=` query parameter rather than the request path, so the rewrite is not optional. All of it is in [Configuration](docs/Configuration.md).

## Contributing

- Fork the repository
- Submit Pull Requests / Merge Requests
- [File issues](../../issues/new) with image tag, run/compose command, and environment details

## Credits

* Powered by [Hubzilla](https://framagit.org/hubzilla/core) — the nomadic, permission-first fediverse platform, and the community that keeps it going
* Builds pull from HomeLabHD mirrors of the upstream repositories; upstream remains [framagit.org/hubzilla](https://framagit.org/hubzilla)

## Disclaimer

> The Software provided hereunder ("Software") is licensed "as-is," without warranties of any kind — express, implied, or federated to you by a hub you have never heard of. The developer makes no promises about functionality, performance, compatibility, security, or availability. Not liable if your nomadic identity wanders off to a hub with better vibes and declines to come back, if an access-control list you set in 2019 is the only reason your relatives cannot see your photos, or if pinning the upstream ref gives you such a smug sense of reproducibility that you forget to back up your database.

> Any positive experiences are owed entirely to the brilliant folks behind Hubzilla and the unstoppable force that is the Open Source community. The developer claims no credit for anything that actually goes right.

## License

Hubzilla is distributed under the [MIT](https://framagit.org/hubzilla/core/-/blob/master/LICENSE) license. This packaging is maintained by HomeLabHD.
