#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Nix Universalis entrypoint

Usage:
  ./entrypoint.sh [options]

Options:
  -u, --username NAME       Target Home Manager username.
  -p, --profile NAME        Profile to enable. Can be repeated.
  -a, --all                 Enable all available profiles.
      --build-only          Build/download the activation package without switching.
      --switch              Apply the selected Home Manager profile. Default action.
  -y, --yes                 Non-interactive confirmation.
      --dry-run             Print actions without installing or running Nix.
  -h, --help                Show this help.

Examples:
  ./entrypoint.sh
  ./entrypoint.sh --username alice --profile dev-core --switch
  ./entrypoint.sh --username alice --profile dev-core --build-only
EOF
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
profiles_dir="$repo_dir/profiles/home"

username="${NIX_UNIVERSALIS_USERNAME:-}"
selected_profiles="${NIX_UNIVERSALIS_PROFILES:-}"
action="${NIX_UNIVERSALIS_ACTION:-switch}"
yes="${NIX_UNIVERSALIS_YES:-0}"
dry_run="${NIX_UNIVERSALIS_DRY_RUN:-0}"
all_profiles=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -u | --username)
      [ "$#" -ge 2 ] || die "missing value for $1"
      username="$2"
      shift 2
      ;;
    -p | --profile)
      [ "$#" -ge 2 ] || die "missing value for $1"
      if [ -n "$selected_profiles" ]; then
        selected_profiles="$selected_profiles $2"
      else
        selected_profiles="$2"
      fi
      shift 2
      ;;
    -a | --all)
      all_profiles=1
      shift
      ;;
    --build-only)
      action="build-only"
      shift
      ;;
    --switch)
      action="switch"
      shift
      ;;
    -y | --yes)
      yes=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[ -d "$profiles_dir" ] || die "profiles directory not found: $profiles_dir"

available_profiles=$(
  find "$profiles_dir" -maxdepth 1 -type f -name '*.nix' \
    ! -name 'default.nix' -exec basename {} .nix \; | sort
)

[ -n "$available_profiles" ] || die "no profiles found in $profiles_dir"

default_username="${USER:-spaceinvaders}"

prompt_username() {
  [ -n "$username" ] && return 0
  if [ "$yes" = 1 ]; then
    username="$default_username"
    return 0
  fi

  printf 'Target username [%s]: ' "$default_username"
  read -r answer
  if [ -n "$answer" ]; then
    username="$answer"
  else
    username="$default_username"
  fi
}

profile_exists() {
  [ -f "$profiles_dir/$1.nix" ]
}

select_all_profiles() {
  selected_profiles=""
  for profile in $available_profiles; do
    if [ -n "$selected_profiles" ]; then
      selected_profiles="$selected_profiles $profile"
    else
      selected_profiles="$profile"
    fi
  done
}

prompt_profiles() {
  if [ "$all_profiles" = 1 ]; then
    select_all_profiles
    return 0
  fi

  if [ -n "$selected_profiles" ]; then
    return 0
  fi

  if [ "$yes" = 1 ]; then
    selected_profiles="dev-core"
    return 0
  fi

  log "Available profiles:"
  i=1
  for profile in $available_profiles; do
    log "  $i) $profile"
    i=$((i + 1))
  done
  printf 'Profiles to enable [dev-core] (names separated by spaces, or "all"): '
  read -r answer

  case "$answer" in
    "" )
      selected_profiles="dev-core"
      ;;
    all )
      select_all_profiles
      ;;
    * )
      selected_profiles="$answer"
      ;;
  esac
}

validate_selection() {
  case "$action" in
    switch | build-only) ;;
    *) die "invalid action: $action" ;;
  esac

  [ -n "$username" ] || die "username cannot be empty"
  [ -n "$selected_profiles" ] || die "at least one profile must be selected"

  for profile in $selected_profiles; do
    profile_exists "$profile" || die "unknown profile: $profile"
  done
}

confirm_selection() {
  log ""
  log "Plan:"
  log "  repo:     $repo_dir"
  log "  user:     $username"
  log "  profiles: $selected_profiles"
  log "  action:   $action"
  if [ "$dry_run" = 1 ]; then
    log "  mode:     dry-run"
  fi

  if [ "$yes" = 1 ]; then
    return 0
  fi

  printf 'Continue? [y/N]: '
  read -r answer
  case "$answer" in
    y | Y | yes | YES) ;;
    *) die "aborted" ;;
  esac
}

load_nix_environment() {
  if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  if [ -r "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
}

ensure_nix() {
  load_nix_environment

  if command -v nix >/dev/null 2>&1; then
    return 0
  fi

  log "Nix is not installed. Installing the multi-user daemon profile."
  log "Installer command:"
  log "  curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon"

  if [ "$dry_run" = 1 ]; then
    return 0
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to install Nix"
  curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
  load_nix_environment
  command -v nix >/dev/null 2>&1 || die "Nix installation finished, but nix is not in PATH. Open a new shell and rerun this script."
}

nix_string() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

detect_system() {
  machine=$(uname -m)
  os=$(uname -s)

  case "$machine:$os" in
    x86_64:Linux) printf '%s\n' "x86_64-linux" ;;
    aarch64:Linux | arm64:Linux) printf '%s\n' "aarch64-linux" ;;
    x86_64:Darwin) printf '%s\n' "x86_64-darwin" ;;
    arm64:Darwin | aarch64:Darwin) printf '%s\n' "aarch64-darwin" ;;
    *) die "unsupported system: $machine:$os" ;;
  esac
}

make_temp_flake() {
  tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/nix-universalis.XXXXXX")
  tmp_flake_dir="$tmp_dir"
  trap 'rm -rf "$tmp_dir"' EXIT INT TERM

  modules_file="$tmp_dir/modules.nix"
  {
    log "{ nix-universalis }:"
    log "["
    for profile in $selected_profiles; do
      log "  \"\${nix-universalis}/profiles/home/$profile.nix\""
    done
    log "]"
  } > "$modules_file"

  repo_escaped=$(nix_string "$repo_dir")
  user_escaped=$(nix_string "$username")
  system_escaped=$(nix_string "$(detect_system)")

  cat > "$tmp_dir/flake.nix" <<EOF
{
  description = "Temporary Nix Universalis activation for $user_escaped";

  inputs = {
    nix-universalis.url = "path:$repo_escaped";
    nixpkgs.follows = "nix-universalis/nixpkgs";
    home-manager.follows = "nix-universalis/home-manager";
  };

  outputs = {
    nixpkgs,
    home-manager,
    nix-universalis,
    ...
  }: let
    system = "$system_escaped";
    username = "$user_escaped";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages.\${system}.home-manager = home-manager.packages.\${system}.home-manager;

    homeConfigurations.activation = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit username;
      };
      modules = import ./modules.nix { inherit nix-universalis; };
    };
  };
}
EOF
}

run_nix_action() {
  make_temp_flake

  case "$action" in
    build-only)
      cmd="nix build 'path:$tmp_flake_dir#homeConfigurations.activation.activationPackage'"
      if [ "$dry_run" = 1 ]; then
        log "$cmd"
      else
        nix build "path:$tmp_flake_dir#homeConfigurations.activation.activationPackage"
      fi
      ;;
    switch)
      cmd="nix run 'path:$tmp_flake_dir#home-manager' -- switch --flake 'path:$tmp_flake_dir#activation'"
      if [ "$dry_run" = 1 ]; then
        log "$cmd"
      else
        nix run "path:$tmp_flake_dir#home-manager" -- switch --flake "path:$tmp_flake_dir#activation"
      fi
      ;;
  esac
}

prompt_username
prompt_profiles
validate_selection
confirm_selection
ensure_nix
run_nix_action

log ""
log "Done."
