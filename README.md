# Nix Universalis

Portable Home Manager graph for a universal developer core.

Project scope, package inventory, priorities, and next steps are documented in
[`docs/PROJECT_PLAN.md`](docs/PROJECT_PLAN.md).

This repository is intentionally separate from `NixOS-Hyprland`. The first cut
enables priority 5 and priority 4 developer tools by default:

- `graphs/dev-core/p5`: essential, portable dev core.
- `graphs/dev-core/p4`: strong general-purpose core, still portable.
- `graphs/subgraphs/cli-plus`: priority 3 opt-in TUI/CLI extras by category.
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
./entrypoint.sh --username alice --profile dev-core --subgraph cli-plus-git-tui --switch
./entrypoint.sh --username alice --profile dev-core --all-subgraphs --switch
```

When run interactively, the entrypoint first installs or loads Nix, then opens a
subgraph selector powered by `fzf` from `nixpkgs`. Move with arrows, toggle with
`Ctrl-j`/`Ctrl-k`, toggle with `Tab`, inspect the preview pane to see the exact
packages each subgraph installs, and press `Enter` to continue to the final
confirmation:

- `cli-plus-git-tui`: `lazygit`
- `cli-plus-network`: `mtr`, `trippy`, `socat`, `ethtool`, `bandwhich`, `netop`, `ncftp`
- `cli-plus-containers`: `distrobox`, `ctop`, `lazydocker`
- `cli-plus-terminal-identity`: `fastfetch`, `onefetch`, `starship`
- `cli-plus-disk-process`: `atop`, `glances`, `caligula`

If the `fzf` TUI cannot run, the entrypoint falls back to a portable numbered
selector.

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
