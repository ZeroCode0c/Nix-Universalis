# Nix Universalis: alcance y plan

## Objetivo

Nix Universalis busca ser un grafo portable de Home Manager para levantar un
entorno de desarrollo útil en cualquier máquina: laptop, VM, desktop, TTY,
servidor o contenedor. La primera etapa no intenta reproducir el sistema
Hyprland completo; extrae solo el núcleo de desarrollo con baja entropía.

## Principios

- Home Manager primero.
- No modificar ni borrar `NixOS-Hyprland`; solo copiar configuraciones útiles.
- Separar el grafo por pesos y subgrafos.
- Mantener `dev-core` portable y no acoplado a desktop, hardware ni lenguajes.
- Agregar toolchains y LSPs como subgrafos posteriores.
- Probar primero con Docker/dry-run/build-only; después validar en VM.
- El entrypoint debe ser plug and play y no asumir que Nix ya existe.

## Pesos

- `5`: esencial, portable, vive como subgrafo seleccionable.
- `4`: core fuerte, portable, vive como subgrafo seleccionable.
- `3`: útil general, vive como subgrafo opt-in.
- `2`: preferencia/personalización, no bloquea desarrollo.
- `1`: fuera del dev core actual.

## Prioridad 5

Todos los elementos P5 se exponen desde el selector del entrypoint. El perfil
base no importa herramientas si no fueron seleccionadas.

| Subgrafo | Categoría | Paquetes/configs |
| --- | --- | --- |
| `cli-base-tools` | Base CLI | `bc`, `curl`, `jq`, `killall`, `rsync`, `tree`, `unrar`, `unzip`, `wget` |
| `dev-build-base` | Build base | `gcc`, `gnumake`, `cmake`, `openssl` |
| `editors-nvim` | Editores | `neovim`, `micro`, `dots/nvim`, configuración de `micro` |
| `dev-git` | Git | `git`, `delta`, configuración de `git` |
| `dev-nix-workflow` | Nix workflow | `nh`, `alejandra`, `nix-prefetch-git`, `nix-output-monitor`, `nvd`, `nixd`, `nixfmt`, `nixpkgs-fmt` |
| `files-search` | Búsqueda/archivos | `fzf`, `ripgrep`, `fd`, `findutils`, `bat`, `bat-extras.batman`, `bat-extras.batpipe` |
| `shell-zsh` | Shell workflow | `zsh`, `oh-my-zsh`, autosuggestions, syntax highlighting, `zoxide`, `zshnip`, configuración de `zsh` |
| `terminals-tmux` | Multiplexor | `tmux`, configuración de `tmux` |

Nota: `home-manager` se activa con `programs.home-manager.enable`; no se añade
como paquete manual porque duplica derivaciones en el perfil.

Nota: `clang` se sacó del core porque entra en conflicto con `gcc` en un mismo
perfil de Home Manager al exportar `bin/ld`. Debe vivir en el subgrafo C/C++.

## Prioridad 4

Todos los elementos P4 también son subgrafos seleccionables.

| Subgrafo | Categoría | Paquetes/configs |
| --- | --- | --- |
| `files-yazi` | File navigation | `eza`, `lsd`, `yazi`, Yazi plugins, `dots/yazi-source` |
| `cli-docs` | Docs rápidas | `tealdeer`, `mdcat`, `frogmouth` |
| `cli-monitoring` | Terminal monitoring | `htop`, `btop`, `bottom`, `ncdu`, `dua`, `duf`, `dysk`, `gdu`, `parallel-disk-usage` |
| `cli-metrics` | Dev metrics/process | `tokei`, `hyperfine`, `pik`, `erdtree`, `lstr` |

## Terminales

| Subgrafo | Paquetes/configs |
| --- | --- |
| `terminals-kitty-zellij` | `kitty`, `dots/kitty`, `zellij`, configuración de `zellij` |

## Prioridad 3

Estos paquetes son útiles, pero no deberían contaminar selecciones mínimas.
Viven como subgrafos temáticos seleccionables desde el entrypoint.

| Subgrafo | Categoría | Paquetes |
| --- | --- | --- |
| `dev-git-tui` | Git TUI | `lazygit` |
| `network-cli` | Network CLI | `mtr`, `trippy`, `socat`, `ethtool`, `bandwhich`, `netop`, `ncftp` |
| `containers-cli` | Containers CLI | `distrobox`, `ctop`, `lazydocker` |
| `cli-terminal-identity` | Terminal identity | `fastfetch`, `onefetch`, `starship` |
| `system-disk-process` | Disk/proc extra | `atop`, `glances`, `caligula` |

## Prioridad 2

Paquetes de preferencia visual, identidad o gusto personal. Son candidatos a un
subgrafo `personal-cli` o `terminal-aesthetics`.

| Categoría | Paquetes |
| --- | --- |
| Prompt/tema | `oh-my-posh` |
| Visual CLI | `figlet`, `lolcat`, `cmatrix` |
| Fetch tools | `macchina`, `hyfetch`, `pfetch`, `ipfetch`, `cpufetch` |
| Terminal media | `mcat` |

## Prioridad 1: fuera del dev core

Estos paquetes no entran en la etapa actual. Pueden aparecer después como
subgrafos separados: desktop, Hyprland, multimedia, hardware, virtualización,
apps personales, etc.

| Motivo | Paquetes |
| --- | --- |
| Hyprland/Wayland/UI | `hypridle`, `hyprpolkitagent`, `pyprland`, `hyprlang`, `hyprshot`, `hyprcursor`, `nwg-displays`, `nwg-look`, `waypaper`, `waybar`, `waybar-weather`, `hyprland-qt-support`, `rofi`, `slurp`, `swappy`, `swaynotificationcenter`, `wallust`, `wdisplays`, `wl-clipboard`, `wtype`, `wlr-randr`, `wlogout`, `quickshell`, `ags`, `cliphist`, `awww` |
| Desktop/apps | `firefox`, `google-chrome`, `discord`, `telegram-desktop`, `proton-pass`, `proton-vpn`, `obs-studio`, `vlc`, `loupe`, `eog`, `baobab`, `gnome-system-monitor`, `mission-center`, `thunar`, `mousepad`, `file-roller`, `xarchiver`, `yad` |
| Audio/media | `ffmpeg`, `mpv`, `yt-dlp`, `cava`, `ncmpcpp`, `mpd`, `mpc`, `pamixer`, `pavucontrol`, `playerctl` |
| Theme/GTK/Qt | `gtk-engine-murrine`, `glib`, `gsettings-qt`, `kdePackages.qt6ct`, `kdePackages.qtwayland`, `kdePackages.qtstyleplugin-kvantum`, `libsForQt5.qtstyleplugin-kvantum`, `libsForQt5.qt5ct`, `libappindicator`, `libnotify`, `sweet`, `beauty-line-icon-theme` |
| Hardware/sistema | `power-profiles-daemon`, `btrfs-progs`, `cpufrequtils`, `pciutils`, `nvtopPackages.full`, `v4l-utils`, `smartmontools`, `brightnessctl`, `lm_sensors`, `cyme`, `cpu-x`, `cpuid`, `inxi` |
| Virtualización/personal | `virt-viewer`, `libvirt`, `rclone`, `appimage-run`, `kdeconnect-kde`, `steam` |

## Subgrafos de lenguaje pendientes

Estos paquetes ya fueron identificados, pero quedan fuera de `dev-core`. Deben
entrar como subgrafos independientes para evitar acoplar el core a lenguajes
específicos.

| Subgrafo | Paquetes |
| --- | --- |
| JS/TS/Web | `nodejs`, `vscode-langservers-extracted`, `tailwindcss-language-server`, `typescript-language-server`, `prettierd` |
| Lua | `lua-language-server`, `stylua`, `luarocks` |
| Python | `basedpyright`, `ruff`, `black`, `python3Packages.pytest`, `python3Packages.mypy`, `python3Packages.debugpy` |
| Bash | `bash-language-server`, `shfmt` |
| Go | `gopls`, `gotools`, `golines`, `gofumpt`, `delve`, `golangci-lint`, `go-tools` |
| Rust | `cargo-flamegraph`, `cargo-criterion`, `cargo-expand`, `cargo-deny`, `cargo-audit`, `cargo-nextest`, `cargo-watch`, `cargo-outdated`, `perf-tools` |
| C/C++ | `clang`, `clang-tools`, `lldb`, `valgrind`, `cppcheck`, `include-what-you-use` |
| Haskell | `haskell-language-server`, `ormolu`, `hlint`, `stack`, `haskellPackages.hoogle` |
| Config formats | `yaml-language-server`, `taplo` |

## Estado actual

Implementado:

- `graphs/cli`
- `graphs/dev`
- `graphs/editors`
- `graphs/files`
- `graphs/shell`
- `graphs/terminals`
- `graphs/network`
- `graphs/containers`
- `graphs/system`
- `profiles/home/dev-core.nix`
- `entrypoint.sh`
- Docker smoke test dry-run
- Flake con Home Manager standalone
- Dots copiados para Neovim y Yazi

Verificaciones actuales:

```sh
nix fmt
nix flake check
nix build .#homeConfigurations.spaceinvaders.activationPackage
./entrypoint.sh --username tester --profile dev-core --build-only --yes
./tests/docker/run.sh
```

## Siguientes pasos

1. Endurecer `entrypoint.sh`.
   - Añadir opción `--repo-url` para instalación remota desde Git.
   - Añadir modo `--no-install-nix` para pruebas controladas.
   - Mejorar mensajes cuando el instalador de Nix requiere abrir una nueva shell.

2. Probar Docker con Nix real.
   - Crear un Dockerfile separado para single-user Nix o usar una imagen base con Nix.
   - Validar `build-only` dentro de contenedor.
   - Mantener el test actual como smoke test rápido sin instalación.

3. Validar en VM limpia.
   - Usuario distinto de `spaceinvaders`.
   - Nix ausente al inicio.
   - `entrypoint.sh --profile dev-core --switch`.
   - Logout/login o nueva shell tras instalación daemon si hace falta.

4. Reducir acoplamiento de dots.
   - Revisar `dots/nvim` porque contiene plugins orientados a lenguajes.
   - Separar config base de Neovim y plugins por lenguaje.
   - Evaluar si `semsearch` debe ser core o subgrafo de conocimiento/lenguaje.

5. Crear subgrafos temáticos P3.
   - Network CLI.
   - Containers CLI.
   - Terminal identity.
   - Utilidades no esenciales pero muy útiles.
   - Mantenerlos opt-in desde el entrypoint.

6. Crear subgrafos por lenguaje.
   - `languages/nix`
   - `languages/python`
   - `languages/rust`
   - `languages/go`
   - `languages/web`
   - `languages/cpp`
   - `languages/haskell`

7. Crear subgrafos fuera del core.
   - `desktop/hyprland`
   - `desktop/apps`
   - `media`
   - `hardware`
   - `virtualization`
   - `personal`

8. Definir política de perfiles.
   - `dev-core`: perfil Home Manager mínimo.
   - P5/P4/P3: subgrafos seleccionables por categoría.
   - `full-dev`: core + lenguajes seleccionados.

## Riesgos conocidos

- Home Manager puede chocar si dos paquetes exportan el mismo path.
- Algunas configuraciones copiadas todavía tienen referencias personales.
- El instalador daemon de Nix puede requerir privilegios y reiniciar shell.
- Neovim puede cargar plugins que esperan toolchains no instalados todavía.
- Docker no replica perfectamente una VM o máquina real con systemd.
