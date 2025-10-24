# SearXNG Ansible role

This is an [Ansible](https://www.ansible.com/) role which installs [SearXNG](https://github.com/searxng/searxng) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

This role *implicitly* depends on:

- [`com.devture.ansible.role.playbook_help`](https://github.com/devture/com.devture.ansible.role.playbook_help)
- [`com.devture.ansible.role.systemd_docker_base`](https://github.com/devture/com.devture.ansible.role.systemd_docker_base)

For an Ansible playbook which integrates this role and makes it easier to use, see the [mash-playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

## Notice

This repository was restored from the galaxy-pulled role when the original repository at https://git.sergiodj.net/sergiodj/ansible-role-searxng.git was down due to server issues.
The git tag `v1.0.0-0` represents the unmodified state of the original repository's role at the time of restoration.
