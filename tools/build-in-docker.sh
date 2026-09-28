#!/usr/bin/env bash
# Runs make in the devlink-rescue build container, as the calling user, with
# the repository mounted at the same path. Everything make fetches must
# already be in buildroot/dl: the container has no login for the private
# repos (devlink, falcon-boot), so run `make classic-source` first on a
# machine that has one, and copy the tree across.
#
#   tools/build-in-docker.sh classic
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
image=devlink-rescue-build

docker build -q -t "$image" -f "$here/tools/Dockerfile.build" "$here/tools" >/dev/null
exec docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp \
    -v "$here:$here" -w "$here" "$image" make "$@"
