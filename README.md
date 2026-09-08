# hubzilla

A **rootless** container image for [Hubzilla](https://hubzilla.org/) — the federated social platform built around **nomadic identity**: a channel is a portable, cryptographically-owned thing that can live on several hubs at once, so an account outlives the server it was created on. Hubzilla speaks its native **Zot** protocol *and* **ActivityPub** (Mastodon, Pixelfed, Lemmy, …), and puts an **access-control list on every object** — each post, photo, file, wiki page and event. Core and the official addon set are cloned at a **pinned upstream ref at build time** and baked in.

<!-- sf:project:start -->
[![GitHub](https://img.shields.io/badge/GitHub-mirror-181717?logo=github)](https://github.com/HomeLabHD/hubzilla) [![GitLab](https://img.shields.io/badge/GitLab-source-FC6D26?logo=gitlab)](https://gitlab.prplanit.com/HomeLabHD/hubzilla) [![license](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/license.svg)](https://github.com/HomeLabHD/hubzilla/blob/main/LICENSE) [![Open Issues](https://img.shields.io/github/issues/HomeLabHD/hubzilla)](https://github.com/HomeLabHD/hubzilla/issues) [![Open PRs](https://img.shields.io/github/issues-pr/HomeLabHD/hubzilla)](https://github.com/HomeLabHD/hubzilla/pulls) [![Contributors](https://img.shields.io/github/contributors/HomeLabHD/hubzilla)](https://github.com/HomeLabHD/hubzilla/graphs/contributors) [![donate](https://img.shields.io/badge/donate-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/T6T41IT163) [![sponsor](https://img.shields.io/badge/sponsor-EA4AAA?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/HomeLabHD)
<!-- sf:project:end -->
<!-- sf:badges:start -->
[![release](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/release.svg)](https://github.com/HomeLabHD/hubzilla/releases) [![build](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/build.svg)](https://gitlab.prplanit.com/HomeLabHD/hubzilla/-/pipelines) [![Last Commit](https://img.shields.io/github/last-commit/HomeLabHD/hubzilla)](https://github.com/HomeLabHD/hubzilla/commits) [![StageFreight](https://img.shields.io/badge/StageFreight-0.11.0--dev+b4a93f0-310937?logo=readthedocs&logoColor=white)](https://stagefreight.prplanit.com)
<!-- sf:badges:end -->
<!-- sf:image:start -->
[![GHCR](https://img.shields.io/badge/GHCR-homelabhd%2Fhubzilla-181717?logo=github&logoColor=white)](https://github.com/HomeLabHD/hubzilla/pkgs/container/hubzilla) [![Docker](https://img.shields.io/badge/Docker-hlhd%2Fhubzilla-2496ED?logo=docker&logoColor=white)](https://hub.docker.com/r/hlhd/hubzilla) [![pulls](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/pulls.svg)](https://hub.docker.com/r/hlhd/hubzilla) [![Harbor](https://img.shields.io/badge/Harbor-hlhd%2Fhubzilla-60b932)](https://cr.pcfae.com/harbor/projects)

[![latest](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/release-latest.svg)](https://github.com/HomeLabHD/hubzilla/pkgs/container/hubzilla) ![updated](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/release-updated.svg) [![size](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/release-size.svg)](https://github.com/HomeLabHD/hubzilla/pkgs/container/hubzilla) [![latest-dev](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/dev-latest.svg)](https://github.com/HomeLabHD/hubzilla/pkgs/container/hubzilla) ![updated](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/dev-updated.svg) [![size](https://raw.githubusercontent.com/HomeLabHD/hubzilla/main/.stagefreight/scribe/dev-size.svg)](https://github.com/HomeLabHD/hubzilla/pkgs/container/hubzilla)
<!-- sf:image:end -->

### Documentation

| Topic | |
|-------|-|
| [Configuration](docs/Configuration.md) | Environment reference, writable paths, database, proxy requirements and background jobs |

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
| **Routing ships with it** | Hubzilla routes on a `q=` parameter, answers `.well-known` from `index.php`, and needs the `Authorization` header for DAV. Those are the app's rules, so nginx and its config are in the image — not retyped into every deployment, and not left behind by an upgrade |
| **Serves HTTP directly** | nginx + php-fpm under tini on port 8080. One container, no sidecar, no supervisor |

## Image contents

<details>
<summary>Base image &amp; installed components (click to expand)</summary>

Base Image:
<!-- sf:contents-base:start -->
[![php 8.3](https://img.shields.io/badge/php-8.3-0078D4?style=flat)](https://hub.docker.com/_/php)
<!-- sf:contents-base:end -->

PHP extensions: `gd` (freetype + jpeg), `pdo`, `pdo_mysql`, `zip`, `exif`, `intl`, `bcmath`, `gmp`, `imagick`

Packages (apt): `nginx`, `tini`, `imagemagick`, `msmtp`, `libzip4`

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

Hubzilla needs a MySQL/MariaDB or PostgreSQL database, a mounted `.htconfig.php`, and persistent storage for `store/`. The container serves **HTTP on 8080** and needs no web server in front of it beyond your TLS terminator — pass `X-Forwarded-Proto`, or the session cookie is issued without `Secure` and browsers discard it. All of it is in [Configuration](docs/Configuration.md).

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
