# Nix Universalis

Portable Home Manager graph for a universal developer core.

This repository is intentionally separate from `NixOS-Hyprland`. The first cut
contains only priority 5 and priority 4 developer tools:

- `graphs/dev-core/p5`: essential, portable dev core.
- `graphs/dev-core/p4`: strong general-purpose core, still portable.
- `profiles/home/dev-core.nix`: Home Manager entrypoint that activates the graph.
- `dots/`: copied configuration data used by graph modules.

Language toolchains and LSP packs are intentionally excluded for now. They should
be added later as independent subgraphs. This includes `clang`, because it
conflicts with `gcc` in a single Home Manager profile by exporting the same
`bin/ld` path.

Build/check:

```sh
nix flake check
```

Entrypoint:

```sh
./entrypoint.sh
./entrypoint.sh --username alice --profile dev-core --build-only
./entrypoint.sh --username alice --profile dev-core --switch
```

If Nix is missing, the entrypoint installs it with the official daemon installer:

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

Apply:

```sh
home-manager switch --flake .#spaceinvaders
```

Docker smoke test:

```sh
./tests/docker/run.sh
```
