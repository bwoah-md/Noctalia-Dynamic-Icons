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
    local script="$1"
    local schema_pkg
    local schema_file
    local schema_dir

    # Locate GNOME schemas in the Nix store
    schema_pkg="$(nix eval --raw nixpkgs#gsettings-desktop-schemas.outPath)" ||
        return 1

    schema_file="$(find "$schema_pkg" -name gschemas.compiled -print -quit)"

    if [[ -z "$schema_file" ]]; then
        echo "[error] Could not locate compiled GNOME schemas."
        return 1
    fi

    schema_dir="${schema_file%/*}"

    echo "[info] Using GNOME schemas: $schema_dir"
    echo "[info] Running installer: $script"

    # Temporary environment containing all installer dependencies
    nix shell \
        nixpkgs#glib \
        nixpkgs#gsettings-desktop-schemas \
        nixpkgs#gtk3 \
        nixpkgs#git \
        nixpkgs#curl \
        nixpkgs#gnused \
        nixpkgs#gnugrep \
        nixpkgs#findutils \
        nixpkgs#coreutils \
        nixpkgs#util-linux \
        nixpkgs#psmisc \
        nixpkgs#ncurses \
        -c bash -c '
            export GSETTINGS_SCHEMA_DIR="$1"
            set -o pipefail
            curl -fsSL "$2" | bash
        ' _ "$schema_dir" \
        "https://raw.githubusercontent.com/bwoah-md/noctalia-dynamic-icons/main/$script"
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
