#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
docker build -f "$repo_dir/tests/docker/Dockerfile" "$repo_dir"
