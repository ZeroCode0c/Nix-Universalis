# Nix Universalis: arquitectura y estado actual

## Objetivo

Nix Universalis es un instalador portable de entorno de usuario basado en
Nix + Home Manager. Está pensado para levantar un entorno de terminal y
desarrollo en máquinas nuevas, incluyendo distribuciones no NixOS como Kali.

El proyecto no intenta reproducir `NixOS-Hyprland`. Solo porta componentes de
usuario que pueden funcionar como Home Manager standalone.

## Principios

- Home Manager primero.
- El perfil base debe ser mínimo.
- Todo lo instalable debe estar expuesto como subgrafo seleccionable.
- No debe existir un “core oculto”.
- El entrypoint debe ser plug and play: si Nix no existe, lo instala.
- La selección interactiva debe mostrar qué se va a instalar antes de aplicar.
- Las herramientas de lenguaje, desktop, multimedia y hardware deben ser
  subgrafos separados cuando se agreguen.

## Flujo del EntryPoint

`entrypoint.sh` ejecuta este flujo:

1. Detecta el usuario objetivo.
2. Selecciona perfil Home Manager.
3. Valida perfil.
4. Carga o instala Nix.
5. Abre selector de subgrafos con `fzf` desde `nixpkgs`.
6. Genera una flake temporal con los subgrafos seleccionados.
7. Ejecuta `build-only` o `switch`.

Si la TUI de `fzf` no puede ejecutarse, cae a un selector numerado portable.

## Perfil

El único perfil actual es:

| Perfil | Propósito |
| --- | --- |
| `dev-core` | Perfil Home Manager mínimo. Define usuario, home, `stateVersion` y activa `programs.home-manager.enable`. No instala herramientas por sí mismo. |

## Estructura de Grafos

La carpeta `graphs/` está organizada por tema:

```text
graphs/
  cli/
  containers/
  dev/
  editors/
  files/
  network/
  shell/
  system/
  terminals/
```

Cada archivo dentro de esas carpetas es un subgrafo seleccionable desde el
entrypoint.

## Subgrafos Actuales

| Subgrafo | Ruta | Contenido |
| --- | --- | --- |
| `cli-base-tools` | `graphs/cli/base-tools.nix` | `bc`, `curl`, `jq`, `killall`, `rsync`, `tree`, `unrar`, `unzip`, `wget` |
| `cli-docs` | `graphs/cli/docs.nix` | `tealdeer`, `mdcat`, `frogmouth` |
| `cli-monitoring` | `graphs/cli/monitoring.nix` | `htop`, `btop`, `bottom`, `ncdu`, `dua`, `duf`, `dysk`, `gdu`, `parallel-disk-usage` |
| `cli-metrics` | `graphs/cli/metrics.nix` | `erdtree`, `hyperfine`, `lstr`, `pik`, `tokei` |
| `cli-terminal-identity` | `graphs/cli/terminal-identity.nix` | `fastfetch`, `onefetch`, `starship` |
| `containers-cli` | `graphs/containers/cli.nix` | `distrobox`, `ctop`, `lazydocker` |
| `dev-build-base` | `graphs/dev/build-base.nix` | `cmake`, `gcc`, `gnumake`, `openssl` |
| `dev-git` | `graphs/dev/git.nix` | `git`, `delta`, aliases/config Git |
| `dev-git-tui` | `graphs/dev/git-tui.nix` | `lazygit` |
| `dev-nix-workflow` | `graphs/dev/nix-workflow.nix` | `nh`, `alejandra`, `nix-output-monitor`, `nix-prefetch-git`, `nvd`, `nixd`, `nixfmt`, `nixpkgs-fmt` |
| `editors-nvim` | `graphs/editors/nvim.nix` | `neovim`, `micro`, `dots/nvim`, configuración de Micro |
| `files-search` | `graphs/files/search.nix` | `fzf`, `bat`, `batman`, `batpipe`, `fd`, `findutils`, `ripgrep` |
| `files-yazi` | `graphs/files/yazi.nix` | `eza`, `yazi`, plugins/config de Yazi |
| `network-cli` | `graphs/network/cli.nix` | `mtr`, `trippy`, `socat`, `ethtool`, `bandwhich`, `netop`, `ncftp` |
| `shell-zsh` | `graphs/shell/zsh.nix` | `zsh`, Oh My Zsh, autosuggestions, syntax highlighting, `zoxide`, `zshnip`, aliases |
| `system-disk-process` | `graphs/system/disk-process.nix` | `atop`, `glances`, `caligula` |
| `terminals-kitty-zellij` | `graphs/terminals/kitty-zellij.nix` | `kitty`, `dots/kitty`, `zellij`, config de Zellij |
| `terminals-tmux` | `graphs/terminals/tmux.nix` | `tmux`, configuración de Tmux |

## Dotfiles Portados

| Ruta | Usado por |
| --- | --- |
| `dots/nvim` | `editors-nvim` |
| `dots/yazi-source` | `files-yazi` |
| `dots/kitty` | `terminals-kitty-zellij` |

## Comandos de Validación

```sh
sh -n entrypoint.sh
nix fmt -- --check README.md docs/PROJECT_PLAN.md profiles/home/dev-core.nix graphs/**/*.nix
nix flake check
./entrypoint.sh --username tester --profile dev-core --build-only --yes
./entrypoint.sh --username tester --profile dev-core --subgraph editors-nvim --build-only --yes
./entrypoint.sh --username tester --profile dev-core --subgraph terminals-kitty-zellij --build-only --yes
```

## Comandos de Uso

Interactivo:

```sh
./entrypoint.sh
```

Sin aplicar cambios:

```sh
./entrypoint.sh --build-only
```

No interactivo con todos los subgrafos:

```sh
./entrypoint.sh --username kali --profile dev-core --all-subgraphs --switch --yes
```

No interactivo con un subgrafo:

```sh
./entrypoint.sh --username kali --profile dev-core --subgraph editors-nvim --switch --yes
```

## Riesgos Conocidos

- `dots/nvim` todavía contiene plugins orientados a lenguajes. Debe separarse en
  base y subgrafos de lenguaje.
- Home Manager puede chocar si dos paquetes exportan el mismo path.
- El instalador daemon de Nix puede requerir `sudo`.
- En shells abiertas antes de instalar Nix, puede hacer falta abrir una nueva
  sesión para que el entorno quede cargado.
- Docker no reemplaza una validación en VM limpia con systemd.

## Siguientes Pasos

1. Separar `dots/nvim` en base + lenguajes.
2. Crear subgrafos `languages/*`.
3. Añadir modo `--no-install-nix` para pruebas controladas.
4. Añadir `--repo-url` para instalación remota.
5. Validar `switch` completo en VM limpia.
6. Mejorar tests Docker con Nix real, no solo dry-run.
