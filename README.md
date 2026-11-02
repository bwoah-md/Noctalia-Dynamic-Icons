# Noctalia Dynamic Icons

Dynamic icon themes for GTK file managers, including Nemo, Thunar, Nautilus and Caja.

These installers create separate icon themes and use Noctalia's color palette to recolor SVG icons dynamically.

## Requirements

- NixOS or a system with the Nix package manager and flakes enabled.
- Noctalia.
- Git.

The installers run inside a temporary `nix shell` environment. Dependencies are not added to your system configuration or permanently installed.

## Installation

### 1. Define the installer helper

Open Bash first if you're using Fish:

```bash
bash
```

Copy and run this helper once:

```bash

run_noctalia_icon_installer() {
    local script="${1:-}"
    local schema_pkg

    # Validate installer argument
    if [[ -z "$script" ]]; then
        echo "[error] Specify an installer."
        return 1
    fi

    # Allow only known installers
    case "$script" in
        papirus.sh|colloid.sh|flat-remix.sh|tela.sh|reversal.sh|zafiro.sh)
            ;;
        *)
            echo "[error] Unknown installer: $script"
            return 1
            ;;
    esac

    # Validate parallel worker count
    if [[ ! "${NIX_ICON_JOBS:-2}" =~ ^[1-9][0-9]*$ ]]; then
        echo "[error] NIX_ICON_JOBS must be a positive integer."
        return 1
    fi

    # Locate GNOME schemas in the Nix store
    schema_pkg="$(nix eval --raw nixpkgs#gsettings-desktop-schemas.outPath)" ||
        return 1

    echo "[info] Running installer: $script"

    # Temporary environment containing all installer dependencies
    nix shell \
        nixpkgs#glib \
        nixpkgs#gsettings-desktop-schemas \
        nixpkgs#gtk3 \
        nixpkgs#git \
        nixpkgs#curl \
        nixpkgs#gnused \
        nixpkgs#findutils \
        nixpkgs#coreutils \
        -c bash -c '
            set -Eeuo pipefail

            # Locate compiled GNOME schemas in the Nix store
            schema_file="$(find "$1" -name gschemas.compiled -print -quit)"

            if [[ -z "$schema_file" ]]; then
                echo "[error] Could not locate compiled GNOME schemas."
                exit 1
            fi

            schema_dir="${schema_file%/*}"

            export GSETTINGS_SCHEMA_DIR="$schema_dir"

            # Limit parallel SVG processing
            export NIX_ICON_JOBS="$3"

            # Prevent changes to global or system Git configuration
            export GIT_CONFIG_GLOBAL=/dev/null
            export GIT_CONFIG_SYSTEM=/dev/null
            export GIT_TERMINAL_PROMPT=0

            export GIT_AUTHOR_NAME="Noctalia Dynamic Icons"
            export GIT_AUTHOR_EMAIL="noctalia-icons@localhost"
            export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
            export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

            # Temporary directory for installer execution data
            tmpdir="$(mktemp -d)"
            trap '\''rm -rf -- "$tmpdir"'\'' EXIT

            # Temporary XDG cache and state
            export XDG_CACHE_HOME="$tmpdir/cache"
            export XDG_STATE_HOME="$tmpdir/state"

            # Preserve the actual graphical session runtime directory
            export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

            echo "[info] Using GNOME schemas: $schema_dir"
            echo "[info] Parallel workers: $NIX_ICON_JOBS"
            echo "[info] Temporary execution environment ready."

            # Download installer into temporary directory
            installer="$tmpdir/installer.sh"

            echo "[info] Downloading installer..."

            curl -fsSL "$2" -o "$installer"

            # Execute installer inside temporary Nix environment
            echo "[info] Executing installer..."

            bash "$installer"

            echo "[info] Installer completed successfully."
        ' _ "$schema_pkg" \
        "https://raw.githubusercontent.com/bwoah-md/noctalia-dynamic-icons/main/$script" \
        "${NIX_ICON_JOBS:-2}"
}
```

### 2. Available themes

#### Papirus

![Papirus Preview](img/papirus.png)

```bash
run_noctalia_icon_installer papirus.sh
```

#### Colloid

![Colloid Preview](img/colloid.png)

```bash
run_noctalia_icon_installer colloid.sh
```

#### Flat Remix

![Flat Remix Preview](img/flat.png)

```bash
run_noctalia_icon_installer flat-remix.sh
```

#### Tela

![Tela Preview](img/tela.png)

```bash
run_noctalia_icon_installer tela.sh
```

#### Reversal

![Reversal Preview](img/reversal.png)

**Currently under maintenance. Use with caution.**

```bash
run_noctalia_icon_installer reversal.sh
```

#### Zafiro

![Zafiro Preview](img/zafiro.png)

```bash
run_noctalia_icon_installer zafiro.sh
```

## Dependencies provided by Nix

| Package | Purpose |
|---|---|
| `glib` | `gsettings` |
| `gsettings-desktop-schemas` | GNOME settings schemas |
| `gtk3` | `gtk-update-icon-cache` |
| `git` | Repository management |
| `curl` | Download installers |
| `gnused` | `sed` |
| `gnugrep` | `grep` |
| `findutils` | `find`, `xargs` |
| `coreutils` | Standard utilities |
| `util-linux` | `flock` |
| `psmisc` | `fuser` |
| `ncurses` | `clear` |

All dependencies are provided temporarily by Nix.

## Notes

- The helper explicitly sets `GSETTINGS_SCHEMA_DIR` so `gsettings` can locate GNOME schemas.
- The helper uses Bash to execute the installers.
- The installers still require a working graphical session for desktop settings changes.
- Reversal is currently under maintenance.
- Running the helper does not modify your NixOS configuration.
