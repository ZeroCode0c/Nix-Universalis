FROM debian:stable-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl findutils sed \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . /workspace

RUN ./entrypoint.sh --username tester --profile dev-core --build-only --yes --dry-run
