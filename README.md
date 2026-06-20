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

Apply:

```sh
home-manager switch --flake .#spaceinvaders
```
