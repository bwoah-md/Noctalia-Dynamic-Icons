#!/usr/bin/env bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[info]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

THEME_NAME="Noctalia-Fluent"
ICONS_DIR="$HOME/.local/share/icons"
NOCTALIA_DIR="$HOME/.config/noctalia"
TEMPLATES_DIR="$NOCTALIA_DIR/templates"
CACHE_DIR="$HOME/.cache/noctalia"
THEME_DIR="$ICONS_DIR/$THEME_NAME"
BASE_DIR="$ICONS_DIR/.${THEME_NAME}-base"
TMP_DIR="$HOME/.cache/noctalia-dynamic-icons/fluent"

export GIT_AUTHOR_NAME="Noctalia Dynamic Icons"
export GIT_AUTHOR_EMAIL="noctalia-icons@localhost"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

clear 2>/dev/null || true
echo -e "${BLUE}"
echo "  _   _            _        _ _          _____ _                  _   "
echo " | \ | | ___   ___| |_ __ _| (_) __ _   |  ___| |_   _  ___ _ __ | |_ "
echo " |  \| |/ _ \ / __| __/ _\` | | |/ _\` |  | |_  | | | | |/ _ \ '_ \| __|"
echo " | |\  | (_) | (__| || (_| | | | (_| |  |  _| | | |_| |  __/ | | | |_ "
echo " |_| \_|\___/ \___|\__\__,_|_|_|\__,_|  |_|   |_|\__,_|\___|_| |_|\__|"
echo -e "${NC}"

echo -e "${BLUE}=== EXCLUSIVE INSTALLER: $THEME_NAME ===${NC}"
echo "1) Install $THEME_NAME"
echo "2) TOTAL CLEANUP"
# Read from the terminal so this also works with: curl ... | bash
read -r -p "Select an option [1-2]: " OPT < /dev/tty

# --- OPTION 2: CLEANUP ---
if [ "$OPT" == "2" ]; then
    info "Removing $THEME_NAME..."
    rm -rf "$THEME_DIR" "$BASE_DIR" \
           "$ICONS_DIR/${THEME_NAME}-light" "$ICONS_DIR/${THEME_NAME}-dark" \
           "$ICONS_DIR/.${THEME_NAME}-light-base" "$ICONS_DIR/.${THEME_NAME}-dark-base"
    rm -rf "$TEMPLATES_DIR/${THEME_NAME}.sh" "$CACHE_DIR/${THEME_NAME}-apply.sh"
    sed -i "/\[theme.templates.user.${THEME_NAME,,}\]/,+3d" "$NOCTALIA_DIR/templates.toml" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Adwaita" 2>/dev/null || true
    success "Cleanup complete."; exit 0
fi

# --- OPTION 1: INSTALL ---
info "Starting installation of $THEME_NAME..."

# 1. Download (cached)
mkdir -p "$HOME/.cache/noctalia-dynamic-icons"
if [ ! -d "$TMP_DIR/.git" ]; then
    info "Cloning repository (will be cached)..."
    rm -rf "$TMP_DIR"
    git clone --depth 1 "https://github.com/vinceliuice/Fluent-icon-theme.git" "$TMP_DIR" || error "Download failed"
else
    info "Updating local cache..."
    git -C "$TMP_DIR" pull -q --rebase || true
fi

# 2. Official installer
info "Running official installer for Fluent..."
bash "$TMP_DIR/install.sh" -d "$ICONS_DIR" -n "$THEME_NAME" standard
rm -rf "$ICONS_DIR/${THEME_NAME}-light" "$ICONS_DIR/${THEME_NAME}-dark" \
       "$ICONS_DIR/.${THEME_NAME}-light-base" "$ICONS_DIR/.${THEME_NAME}-dark-base"

[ -d "$THEME_DIR" ] || error "The installer did not create $THEME_NAME"
[ -d "$BASE_DIR" ]  || error "The installer did not create $BASE_DIR"

# 3. Git snapshot (the real SVGs live in the hidden base, the theme folder only has symlinks)
info "Configuring internal Git for icons..."
cd "$BASE_DIR"
rm -rf .git
git init -q -b original
git config user.name "$GIT_AUTHOR_NAME"
git config user.email "$GIT_AUTHOR_EMAIL"
git add -A
git commit -q -m "original"
git tag -f "original" >/dev/null

# 4. Noctalia template
info "Creating template for Noctalia..."
mkdir -p "$TEMPLATES_DIR" "$CACHE_DIR"
cat > "$TEMPLATES_DIR/${THEME_NAME}.sh" << 'EOF'
#!/usr/bin/env bash
PRI="{{colors.primary.default.hex}}"
C1="${PRI:1}"
THEME_NAME="Noctalia-Fluent"
THEME_DIR="$HOME/.local/share/icons/$THEME_NAME"
BASE="$HOME/.local/share/icons/.${THEME_NAME}-base"
BRANCH="color-${C1}-all-v3"

if git -C "$BASE" show-ref --quiet "refs/heads/$BRANCH"; then
    git -C "$BASE" checkout -q "$BRANCH"
else
    git -C "$BASE" checkout -q "original"
    git -C "$BASE" checkout -q -b "$BRANCH"

    find -L "$BASE" -type f -name "*.svg" -print0 \
        | xargs -0 -r -P "$(nproc)" sed \
            --follow-symlinks -i \
            -e "s/#198ee6/#${C1}/gI" \
            -e "s/#363636/#${C1}/gI"


    git -C "$BASE" commit -q -am "color $BRANCH"
fi

gtk-update-icon-cache -f -t "$THEME_DIR" 2>/dev/null
CURRENT=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
if [[ "$CURRENT" == "$THEME_NAME" ]]; then
    gsettings set org.gnome.desktop.interface icon-theme "hicolor" 2>/dev/null
    sleep 0.3
    gsettings set org.gnome.desktop.interface icon-theme "$THEME_NAME" 2>/dev/null
fi
EOF
chmod +x "$TEMPLATES_DIR/${THEME_NAME}.sh"

# 5. Register in templates.toml
info "Registering in templates.toml..."
touch "$NOCTALIA_DIR/templates.toml"
sed -i "/\[theme.templates.user.${THEME_NAME,,}\]/,+3d" "$NOCTALIA_DIR/templates.toml" 2>/dev/null || true
cat >> "$NOCTALIA_DIR/templates.toml" << EOF

[theme.templates.user.${THEME_NAME,,}]
input_path  = "~/.config/noctalia/templates/${THEME_NAME}.sh"
output_path = "~/.cache/noctalia/${THEME_NAME}-apply.sh"
post_hook   = "bash ~/.cache/noctalia/${THEME_NAME}-apply.sh"
EOF

# 6. Apply theme
gtk-update-icon-cache -f -t "$THEME_DIR" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "$THEME_NAME" 2>/dev/null || true

# --- SYSTEM SYNCHRONIZATION ---
info "Synchronizing GTK and Fuzzel configurations..."
if [ -f "$HOME/.config/fuzzel/fuzzel.ini" ]; then
    sed -i "/^icon-theme=/d" "$HOME/.config/fuzzel/fuzzel.ini" 2>/dev/null || true
    sed -i "/^\[main\]/a icon-theme=$THEME_NAME" "$HOME/.config/fuzzel/fuzzel.ini" 2>/dev/null || true
fi

for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    if [ -f "$f" ]; then
        sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$THEME_NAME/" "$f" 2>/dev/null || true
    fi
done

success "Installation of $THEME_NAME completed!"
info "Refresh your Noctalia color palette to apply changes."
