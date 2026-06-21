# Nix Universalis

## Español

Nix Universalis es un instalador portable de entorno de usuario basado en
Nix + Home Manager. Su objetivo es llevar un entorno de terminal/desarrollo a
máquinas nuevas, incluyendo distros no NixOS como Kali, sin asumir que Nix ya
está instalado.

La herramienta funciona por subgrafos seleccionables. Cada subgrafo representa
una parte del entorno: shell, Neovim, Git, navegación de archivos, terminales,
herramientas de red, contenedores, monitoreo, etc. Si algo no se selecciona, no
se instala.

### Qué hace

- Instala Nix si no existe.
- Activa un perfil de Home Manager para el usuario elegido.
- Permite seleccionar componentes con una TUI basada en `fzf`.
- Muestra qué paquetes instala cada subgrafo antes de aplicarlo.
- Hace backup automático de archivos existentes gestionados por Home Manager.

### Uso rápido

```sh
git clone https://github.com/ZeroCode0c/Nix-Universalis
cd Nix-Universalis
./entrypoint.sh
```

El script preguntará:

1. Usuario objetivo.
2. Perfil Home Manager.
3. Subgrafos a instalar.
4. Confirmación final.

Si Nix no está instalado, el script ejecuta el instalador oficial daemon:

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

### Selector interactivo

Después de cargar o instalar Nix, el script abre un selector `fzf`:

- Flechas: mover cursor.
- `Ctrl-j` / `Ctrl-k`: mover cursor.
- `Tab`: marcar o desmarcar.
- `Enter`: aceptar selección.
- Panel derecho: paquetes y módulo Nix exactos del subgrafo seleccionado.

Si `fzf` no puede ejecutarse, el script usa un selector numerado básico.

### Ejemplos

Instalación interactiva:

```sh
./entrypoint.sh
```

Construir sin aplicar cambios:

```sh
./entrypoint.sh --build-only
```

Ejecutar sin preguntas usando todos los subgrafos:

```sh
./entrypoint.sh --username kali --profile dev-core --all-subgraphs --switch --yes
```

Instalar solo Neovim y su configuración:

```sh
./entrypoint.sh --username kali --profile dev-core --subgraph editors-nvim --switch --yes
```

Instalar solo Kitty + Zellij:

```sh
./entrypoint.sh --username kali --profile dev-core --subgraph terminals-kitty-zellij --switch --yes
```

### Subgrafos disponibles

Algunos subgrafos actuales:

- `editors-nvim`: Neovim, Micro y configuración de Neovim.
- `shell-zsh`: Zsh, Oh My Zsh, zoxide, zshnip y aliases.
- `files-yazi`: eza, Yazi, plugins y configuración.
- `terminals-kitty-zellij`: Kitty, configuración de Kitty, Zellij y configuración.
- `dev-git`: Git y Delta.
- `dev-git-tui`: Lazygit.
- `dev-nix-workflow`: herramientas de Nix.
- `network-cli`: herramientas CLI de red.
- `containers-cli`: herramientas CLI de contenedores.
- `system-disk-process`: herramientas extra de disco/procesos.

### Notas

- El perfil `dev-core` es mínimo. No instala herramientas por sí mismo.
- Todo lo instalable debe estar expuesto como subgrafo seleccionable.
- Al hacer `switch`, Home Manager puede mover dotfiles existentes a backups con
  extensión `nix-universalis-backup-*`.
- El proyecto está separado de `NixOS-Hyprland`; aquí se portan componentes de
  usuario, no configuración de sistema NixOS.

### Validación

```sh
nix flake check
./entrypoint.sh --username tester --profile dev-core --build-only --yes
```

---

## English

Nix Universalis is a portable user-environment installer based on
Nix + Home Manager. Its goal is to bring a terminal/development environment to
new machines, including non-NixOS distributions such as Kali, without assuming
that Nix is already installed.

The tool is built around selectable subgraphs. Each subgraph represents one
part of the environment: shell, Neovim, Git, file navigation, terminals,
network tools, containers, monitoring, and so on. If a subgraph is not selected,
it is not installed.

### What It Does

- Installs Nix if it is missing.
- Activates a Home Manager profile for the selected user.
- Lets you select components through an `fzf` TUI.
- Shows the exact packages installed by each subgraph before applying.
- Automatically backs up existing files managed by Home Manager.

### Quick Start

```sh
git clone https://github.com/ZeroCode0c/Nix-Universalis
cd Nix-Universalis
./entrypoint.sh
```

The script asks for:

1. Target username.
2. Home Manager profile.
3. Subgraphs to install.
4. Final confirmation.

If Nix is missing, the script runs the official daemon installer:

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

### Interactive Selector

After loading or installing Nix, the script opens an `fzf` selector:

- Arrow keys: move cursor.
- `Ctrl-j` / `Ctrl-k`: move cursor.
- `Tab`: toggle selection.
- `Enter`: accept selection.
- Right preview pane: exact packages and Nix module for the highlighted subgraph.

If `fzf` cannot run, the script falls back to a basic numbered selector.

### Examples

Interactive installation:

```sh
./entrypoint.sh
```

Build without applying changes:

```sh
./entrypoint.sh --build-only
```

Run non-interactively with all subgraphs:

```sh
./entrypoint.sh --username kali --profile dev-core --all-subgraphs --switch --yes
```

Install only Neovim and its configuration:

```sh
./entrypoint.sh --username kali --profile dev-core --subgraph editors-nvim --switch --yes
```

Install only Kitty + Zellij:

```sh
./entrypoint.sh --username kali --profile dev-core --subgraph terminals-kitty-zellij --switch --yes
```

### Available Subgraphs

Some current subgraphs:

- `editors-nvim`: Neovim, Micro, and Neovim configuration.
- `shell-zsh`: Zsh, Oh My Zsh, zoxide, zshnip, and aliases.
- `files-yazi`: eza, Yazi, plugins, and configuration.
- `terminals-kitty-zellij`: Kitty, Kitty config, Zellij, and config.
- `dev-git`: Git and Delta.
- `dev-git-tui`: Lazygit.
- `dev-nix-workflow`: Nix workflow tools.
- `network-cli`: network CLI tools.
- `containers-cli`: container CLI tools.
- `system-disk-process`: extra disk/process tools.

### Notes

- The `dev-core` profile is minimal. It does not install tools by itself.
- Anything installable should be exposed as a selectable subgraph.
- During `switch`, Home Manager may move existing dotfiles to backups using the
  `nix-universalis-backup-*` extension.
- This project is separate from `NixOS-Hyprland`; it ports user-level
  components, not NixOS system configuration.

### Validation

```sh
nix flake check
./entrypoint.sh --username tester --profile dev-core --build-only --yes
```
