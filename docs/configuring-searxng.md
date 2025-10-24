<!--
SPDX-FileCopyrightText: 2020 - 2024 MDAD project contributors
SPDX-FileCopyrightText: 2020 - 2024 Slavi Pantaleev
SPDX-FileCopyrightText: 2020 Aaron Raimist
SPDX-FileCopyrightText: 2020 Chris van Dijk
SPDX-FileCopyrightText: 2020 Dominik Zajac
SPDX-FileCopyrightText: 2020 Mickaël Cornière
SPDX-FileCopyrightText: 2022 François Darveau
SPDX-FileCopyrightText: 2022 Julian Foad
SPDX-FileCopyrightText: 2022 Warren Bailey
SPDX-FileCopyrightText: 2023 Antonis Christofides
SPDX-FileCopyrightText: 2023 Felix Stupp
SPDX-FileCopyrightText: 2023 Julian-Samuel Gebühr
SPDX-FileCopyrightText: 2023 Pierre 'McFly' Marty
SPDX-FileCopyrightText: 2024 Thomas Miceli
SPDX-FileCopyrightText: 2024 - 2025 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Setting up SearXNG

This is an [Ansible](https://www.ansible.com/) role which installs an [SearXNG](https://github.com/searxng/searxng-docker/) server to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

SearXNG is a Node.js based free forum software.

See the project's [documentation](https://docs.searxng.org/) to learn what SearXNG does and why it might be useful to you.

## Prerequisites

To run a SearXNG instance it is necessary to prepare a database. You can use [MongoDB](https://mongodb.com) or [Redis](https://redis.io/).

If you are looking for Ansible roles for them, you can check out [ansible-role-mongodb](https://github.com/mother-of-all-self-hosting/ansible-role-mongodb) and [ansible-role-redis](https://github.com/mother-of-all-self-hosting/ansible-role-redis), both of which are maintained by the [Mother-of-All-Self-Hosting (MASH)](https://github.com/mother-of-all-self-hosting) team. The roles for [KeyDB](https://keydb.dev/) ([ansible-role-keydb](https://github.com/mother-of-all-self-hosting/ansible-role-keydb)) and [Valkey](https://valkey.io/) ([ansible-role-valkey](https://github.com/mother-of-all-self-hosting/ansible-role-valkey)) are available as well.

>[!NOTE]
> This role does not support Postgres, as installing with it has been deprecated.

## Adjusting the playbook configuration

To enable the SearXNG with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# searxng                                                              #
#                                                                      #
########################################################################

searxng_enabled: true

########################################################################
#                                                                      #
# /searxng                                                             #
#                                                                      #
########################################################################
```

### Set the hostname

To enable the SearXNG you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
searxng_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

**Note**: hosting the SearXNG under a subpath (by configuring the `searxng_path_prefix` variable) does not seem to be possible due to SearXNG's technical limitations.

### Set a random string for secret key

You also need to set a random string used for the secret key. To do so, add the following configuration to your `vars.yml` file. The value can be generated with `pwgen -s 64 1` or in another way.

```yaml
searxng_config_server_secret_key: YOUR_SECRET_KEY_HERE
```

### Configure a MongoDB database server (optional)

To have SearXNG connect to your MongoDB server, add the following configuration to your `vars.yml` file.

```yaml
searxng_database_mongodb_hostname: YOUR_MONGODB_SERVER_HOSTNAME_HERE
searxng_database_mongodb_port: 27017
searxng_database_mongodb_username: YOUR_MONGODB_SERVER_USERNAME_HERE
searxng_database_mongodb_password: YOUR_MONGODB_SERVER_PASSWORD_HERE
searxng_database_mongodb_name: YOUR_MONGODB_SERVER_DATABASE_NAME_HERE
```

Make sure to replace values for variables with yours.

### Enabling rate limiter with a Valkey server (optional)

Also, you can optionally enable the [rate limiter](https://docs.searxng.org/admin/searx.limiter.html) with a [Valkey](https://redis.io/) server.

If you are looking for an Ansible role for Valkey, you can check out [ansible-role-valkey](https://github.com/mother-of-all-self-hosting/ansible-role-valkey) maintained by the [Mother-of-All-Self-Hosting (MASH)](https://github.com/mother-of-all-self-hosting) team.

To enable the rate limiter with Valkey, add the following configuration to your `vars.yml` file:

```yaml
searxng_config_server_limiter: true

searxng_redis_hostname: YOUR_REDIS_SERVER_HOSTNAME_HERE
searxng_redis_port: 6379
searxng_redis_database: 0
```

Make sure to replace `YOUR_REDIS_SERVER_HOSTNAME_HERE` with your own value.

### Extending the configuration

There are some additional things you may wish to configure about the component.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `searxng_environment_variables_additional_variables` variable

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, SearXNG becomes available at the specified hostname like `https://example.com`.

To get started, open the URL with a web browser, and follow the set up wizard. Some of the details for the database are automatically specified.

On the wizard UI, **the scheme (`HTTPS` or `HTTP`) for the public facing URL is sometimes not detected properly**. Make sure that the correct one is specified, and set it manually if not. The service works even if the correct one is not set, but certain plugins such as [`searxng-plugin-2factor`](https://github.com/julianlam/searxng-plugin-2factor) will not work as expected, as WebAuthn requires the canonical URL to being on the secure contexts (HTTPS).

### Configuring a mailer

The official Docker image which this role uses to configure a SearXNG instance assumes that SendMail would be available as a mailer, which in fact is not. Therefore, sending emails with the default configuration fails with the error `error:sendmail-not-found`. The project [recommends](https://docs.searxng.org/configuring/plugins/emailers/) to use third party mailers with plugins.

## Troubleshooting

The official forum is available at <https://community.searxng.org/>.

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu searxng` (or how you/your playbook named the service, e.g. `mash-searxng`).
