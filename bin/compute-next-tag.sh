#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Prints the tag that the currently checked out commit should be released as,
# or nothing at all if it does not warrant a release.
#
# Usage: bin/compute-next-tag.sh
#
# ---------------------------------------------------------------------------
# SearXNG has no upstream version - read this before changing anything here
# ---------------------------------------------------------------------------
#
# Most roles in the fleet name their tags after the version of the software
# they install. This one cannot: SearXNG publishes no versions.
#
# - github.com/searxng/searxng has no releases and no git tags at all
# - docker.io/searxng/searxng is rebuilt from master several times a week, and
#   each rebuild is tagged `<date>-<short commit hash>` (`2026.8.22-9fea41204`)
#   alongside `latest`
#
# So `searxng_version` in defaults/main.yml is the literal `latest`, there is
# nothing for Renovate to bump, and there is no version to name a tag after.
# The tags this repository has always used encode that absence as the
# placeholder version `1.0.0`, with the release counter carrying all of the
# information: `v1.0.0-0` through `v1.0.0-10` at the time of writing.
#
# This script reproduces that naming rather than inventing a new one, by
# translating the `latest` sentinel into `1.0.0`. It still reads the version
# out of defaults/main.yml, so that the day SearXNG starts publishing versions
# and this role pins one, tagging follows along on its own: pinning
# `searxng_version: 1.2.3` starts a `v1.2.3-N` series with no change here.
#
# ---------------------------------------------------------------------------
#
# Tags look like `v<version>-<release>`:
#
# - if defaults/main.yml points at a version that has never been released,
#   the release counter restarts at 0 (`v1.2.3-0`)
# - otherwise the counter is incremented (`v1.0.0-11`), but only if something
#   that actually affects the role has changed since the last release
#
# Determining the version from defaults/main.yml, rather than from the commit
# message of the pull request that got merged, makes the result independent of
# the order in which pull requests get merged, and lets any change to the role
# (bugfix, feature, dependency bump) release itself without a human tagging.

set -euo pipefail

repository_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repository_path"

defaults_path='defaults/main.yml'

# Paths that shape the behavior of the role for its consumers. A commit
# touching only other paths (a README fix, CI configuration, Molecule tests)
# does not change what a playbook run does, and releasing it would only create
# churn in the repositories that consume this role.
role_defining_paths=(
	'defaults'
	'meta'
	'tasks'
	'templates'
)

# Anchored at the start of the line, so that neither a commented-out example
# nor one of the several other variables ending in `_version` (such as
# `searxng_container_image_self_build_repo_version`) can be picked up instead.
#
# `searxng_version` is a literal value. Deriving the tag from a variable whose
# value is a Jinja expression would put that expression into the tag itself -
# a mistake that has produced tags such as `v{{-0` elsewhere in the fleet.
version="$(sed -nE 's|^searxng_version:[[:space:]]*"?([^"[:space:]]+)"?.*$|\1|p' "$defaults_path" | head -n1)"

if [ -z "$version" ]; then
	echo >&2 "Could not determine the SearXNG version from $defaults_path"
	exit 1
fi

# See the explanation at the top of this file.
if [ "$version" = 'latest' ]; then
	version='1.0.0'
fi

# The version value does not carry a leading `v`, but the tags do. Stripping
# any `v` before prepending one keeps this correct even if the version value
# ever starts carrying one.
tag_prefix="v${version#v}-"

# Of all releases of this version, the highest release number. Sorted
# numerically, so that -10 is recognized as newer than -9. This repository is
# already past that boundary, at `v1.0.0-10`.
last_release="$(git tag --list "${tag_prefix}*" | sed -e "s|^${tag_prefix}||" | grep -E '^[0-9]+$' | sort -n | tail -n1 || true)"

if [ -z "$last_release" ]; then
	echo >&2 "Version $version has never been released"
	echo "${tag_prefix}0"
	exit 0
fi

previous_tag="${tag_prefix}${last_release}"

if git diff --quiet "$previous_tag" HEAD -- "${role_defining_paths[@]}"; then
	echo >&2 "Nothing affecting the role has changed since $previous_tag"
	exit 0
fi

echo >&2 "The role has changed since $previous_tag"
echo "${tag_prefix}$((last_release + 1))"
