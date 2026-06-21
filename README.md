# Nix Universalis

Portable Home Manager graph for a universal developer core.

Project scope, package inventory, priorities, and next steps are documented in
[`docs/PROJECT_PLAN.md`](docs/PROJECT_PLAN.md).

This repository is intentionally separate from `NixOS-Hyprland`. The Home
Manager profile is only the activation shell; tools enter through selectable
subgraphs:

- `graphs/cli`: general CLI tools, docs, metrics, monitoring, identity.
- `graphs/dev`: build, Git, and Nix development workflow.
- `graphs/editors`: editors and editor configs.
- `graphs/files`: search and file navigation.
- `graphs/shell`: shell workflow.
- `graphs/terminals`: terminal emulators and multiplexers.
- `graphs/network`, `graphs/containers`, `graphs/system`: specialized extras.
- `profiles/home/dev-core.nix`: minimal Home Manager activation profile.
- `dots/`: copied configuration data used by selected subgraphs.

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
./entrypoint.sh --username alice --profile dev-core --subgraph editors-nvim --switch
./entrypoint.sh --username alice --profile dev-core --all-subgraphs --switch
```

When run interactively, the entrypoint first installs or loads Nix, then opens a
subgraph selector powered by `fzf` from `nixpkgs`. Move with arrows, toggle with
`Ctrl-j`/`Ctrl-k`, toggle with `Tab`, inspect the preview pane to see the exact
packages each subgraph installs, and press `Enter` to continue to the final
confirmation:

- `editors-nvim`: `neovim`, `micro`, `dots/nvim`
- `shell-zsh`: `zsh`, `oh-my-zsh`, `zoxide`, `zshnip`
- `files-yazi`: `eza`, `yazi`, Yazi plugins/config
- `terminals-kitty-zellij`: `kitty`, Kitty config, `zellij`, Zellij config
- `dev-git-tui`: `lazygit`
- `network-cli`: `mtr`, `trippy`, `socat`, `ethtool`, `bandwhich`, `netop`, `ncftp`
- `containers-cli`: `distrobox`, `ctop`, `lazydocker`
- `cli-terminal-identity`: `fastfetch`, `onefetch`, `starship`
- `system-disk-process`: `atop`, `glances`, `caligula`

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
