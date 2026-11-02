# Noctalia Dynamic Icons

Dynamic icon themes for GTK file managers, including Nemo, Thunar, Nautilus and Caja.

These installers create separate icon themes and use Noctalia's color palette to recolor SVG icons dynamically.

## Requirements

- Noctalia.
- A working graphical desktop session.
- Bash.
- Git and curl (provided temporarily through Nix when using the Nix installation method).

Choose the installation method that matches your system.

## Available Themes

### Papirus

![Papirus Preview](img/papirus.png)

### Colloid

![Colloid Preview](img/colloid.png)

### Flat Remix

![Flat Remix Preview](img/flat.png)

### Tela

![Tela Preview](img/tela.png)

### Reversal

![Reversal Preview](img/reversal.png)

> ***⚠️ Currently under maintenance. Use with caution.***

### Zafiro

![Zafiro Preview](img/zafiro.png)

## Installation

There are two installation methods:

- **Standard installation:** For systems without Nix. Requires the necessary dependencies to be installed on your system.
- **Nix installation:** For NixOS and other systems with Nix and flakes enabled. Dependencies are provided through a temporary `nix shell` environment and are not added to your system configuration.

> ***⚠️ Do not use both methods for the same installation.***

<details>
<summary><strong>1. Standard installation (Non-Nix)</strong></summary>
<br>
This method uses the original installer commands. Dependencies must already be available on your system.

### Dependencies

Install the following dependencies using your distribution's package manager:

| Package / Command | Purpose |
|---|---|
| `bash` | Execute installers |
| `git` | Repository management |
| `curl` | Download installers |
| `sed` | SVG recoloring and configuration editing |
| `grep` | Text searching |
| `find` | Locate SVG files |
| `xargs` | Parallel command execution |
| `coreutils` | Standard utilities |
| `glib` | `gsettings`, `gio` |
| `gsettings-desktop-schemas` | GNOME settings schemas |
| `gtk3` | `gtk-update-icon-cache` |
| `util-linux` | `flock` |
| `psmisc` | `fuser` |
| `ncurses` | `clear` |

Package names may differ between distributions.

### Installation commands

**Papirus**

```bash
curl -fsSL https://raw.githubusercontent.com/bwoah-md/noctalia-dynamic-icons/main/papirus.sh | bash
```

**Colloid**

```bash
curl -fsSL https://raw.githubusercontent.com/bwoah-md/noctalia-dynamic-icons/main/colloid.sh | bash
```

**Flat Remix**

```bash
curl -fsSL https://raw.githubusercontent.com/bwoah-md/noctalia-dynamic-icons/main/flat-remix.sh | bash
```

**Tela**

```bash
curl -fsSL https://raw.githubusercontent.com/bwoah-md/noctalia-dynamic-icons/main/tela.sh | bash
```

**Reversal**

```bash
curl -fsSL https://raw.githubusercontent.com/bwoah-md/noctalia-dynamic-icons/main/reversal.sh | bash
```

**Zafiro**

```bash
curl -fsSL https://raw.githubusercontent.com/bwoah-md/noctalia-dynamic-icons/main/zafiro.sh | bash
```

</details>

<details>
<summary><strong>2. Nix installation</strong></summary>
<br>
For NixOS and other systems with the Nix package manager.

### Requirements

- Nix package manager.
- Nix flakes and `nix-command` enabled.
- Noctalia.
- A working graphical desktop session.

The installers run inside a temporary `nix shell` environment. Dependencies are made available only during execution and are not added to your NixOS configuration or system packages.

Nix may retain downloaded dependencies in the Nix store until garbage collection.

### Step 1. Define the installer helper

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
        nixpkgs#gnugrep \
        nixpkgs#findutils \
        nixpkgs#coreutils \
        nixpkgs#util-linux \
        nixpkgs#psmisc \
        nixpkgs#ncurses \
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
        "https://raw.githubusercontent.com/bwoah-md/noctalia-dynamic-icons/main/$script"
}
```

### Step 2. Install a theme

Run the corresponding command:

**Papirus**

```bash
run_noctalia_icon_installer papirus.sh
```

**Colloid**

```bash
run_noctalia_icon_installer colloid.sh
```

**Flat Remix**

```bash
run_noctalia_icon_installer flat-remix.sh
```

**Tela**

```bash
run_noctalia_icon_installer tela.sh
```

**Reversal**

```bash
run_noctalia_icon_installer reversal.sh
```

**Zafiro**

```bash
run_noctalia_icon_installer zafiro.sh
```

### Dependencies provided by Nix

| Package | Purpose |
|---|---|
| `glib` | `gsettings`, `gio` |
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

</details>

## Notes

- The Nix helper explicitly sets `GSETTINGS_SCHEMA_DIR` so `gsettings` can locate GNOME schemas.
- The Nix helper uses Bash to execute the installers.
- The standard installation method uses the dependencies already installed on your system.
- The Nix installation method provides installer dependencies through a temporary Nix shell environment.
- Temporary execution files, cache and state directories are removed when the Nix installer exits.
- The actual icon themes, recolored SVG files, Git history, generated icon caches and desktop settings remain persistent.
- Some installers maintain their own repository caches under `~/.cache`.
- The installers require a working graphical session for desktop settings changes.
- Neither installation method modifies your NixOS configuration.
- The Nix helper is an execution environment, not a security sandbox. Installers execute with your normal user permissions.
