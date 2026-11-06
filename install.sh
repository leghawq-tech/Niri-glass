#!/bin/bash
set -e

NIRI_SRC="${1:-$HOME/niri}"

if [ ! -d "$NIRI_SRC" ]; then
  echo "Error: niri source directory not found at $NIRI_SRC"
  echo "Usage: ./install.sh [path-to-niri-src]"
  exit 1
fi

# The overlay replaces whole files, so it only fits this niri revision (same pin as flake.nix).
NIRI_REV=49fc6117fd6c043adaa2ead316b82db5ed735d36
if [ "$(git -C "$NIRI_SRC" rev-parse HEAD)" != "$NIRI_REV" ]; then
  echo "Error: $NIRI_SRC is not at niri $NIRI_REV (26.04)."
  echo "Run: git -C \"$NIRI_SRC\" checkout $NIRI_REV"
  exit 1
fi

echo "Copying files to $NIRI_SRC..."
cp src/render_helpers/liquid_glass.rs "$NIRI_SRC/src/render_helpers/"
cp src/render_helpers/shaders/clipped_surface.frag "$NIRI_SRC/src/render_helpers/shaders/"
cp src/render_helpers/background_effect.rs "$NIRI_SRC/src/render_helpers/"
cp src/render_helpers/framebuffer_effect.rs "$NIRI_SRC/src/render_helpers/"
cp src/render_helpers/xray.rs "$NIRI_SRC/src/render_helpers/"
cp src/render_helpers/shaders/mod.rs "$NIRI_SRC/src/render_helpers/shaders/"
cp src/render_helpers/mod.rs "$NIRI_SRC/src/render_helpers/"
cp niri-config/src/appearance.rs "$NIRI_SRC/niri-config/src/"

echo "Building niri..."
cd "$NIRI_SRC" && cargo build --release

echo "Installing to /usr/local/bin/niri-glass..."
sudo cp "$NIRI_SRC/target/release/niri" /usr/local/bin/niri-glass

# Mirrors upstream /usr/bin/niri-session but targets our binary and unit.
echo "Installing /usr/local/bin/niri-glass-session..."
sudo install -m 755 /usr/bin/niri-session /usr/local/bin/niri-glass-session

sudo sed -i \
  -e 's|niri --session|niri-glass --session --config "$HOME/.config/niri/glass.kdl"|g' \
  -e 's|niri\.service|niri-glass.service|g' \
  /usr/local/bin/niri-glass-session

echo "Installing ~/.local/share/systemd/user/niri-glass.service (copy of niri.service)..."
mkdir -p "$HOME/.local/share/systemd/user"
install -m 644 /usr/lib/systemd/user/niri.service "$HOME/.local/share/systemd/user/niri-glass.service"
sed -i \
  -e 's|niri --session|niri-glass --session --config %h/.config/niri/glass.kdl|g' \
  -e 's|^Description=.*|Description=Niri (Liquid Glass) — scrollable-tiling Wayland compositor|' \
  "$HOME/.local/share/systemd/user/niri-glass.service"
systemctl --user daemon-reload

# Own config for niri-glass: stock niri can't parse liquid-glass, so it stays out of config.kdl.
GLASS_CONFIG="$HOME/.config/niri/glass.kdl"
if [ -e "$GLASS_CONFIG" ]; then
  echo "Keeping existing $GLASS_CONFIG"
else
  echo "Creating $GLASS_CONFIG (includes your config.kdl, adds liquid glass)..."
  mkdir -p "$HOME/.config/niri"
  cat >"$GLASS_CONFIG" <<'EOF'
// Config for niri-glass only. Your normal niri config is pulled in first,
// then the liquid-glass rule below is added on top.
include "config.kdl"

window-rule {
    match app-id=".*"
    background-effect {
        blur true
        xray true
        liquid-glass {
            refraction-strength 3.0
            power-factor 10
            refraction-power 1.0
            glow-weight 0.0001
            edge-lighting 0.2
            saturation 0.9
            vibrancy 0.2
            adaptive-dim 0.2
            adaptive-boost 0.2
            physical-refraction 0
            lens-distortion 0
            fringing 0
        }
    }
}
EOF
fi
if [ ! -e "$HOME/.config/niri/config.kdl" ]; then
  echo "Warning: ~/.config/niri/config.kdl does not exist; glass.kdl includes it."
  echo "Start stock niri once to create it, or remove the include line from glass.kdl."
fi

# Wayland session entry — used by login managers. Points at the session wrapper
echo "Registering Wayland session entry..."
sudo tee /usr/share/wayland-sessions/niri-glass.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Niri (Liquid Glass)
Comment=Niri with liquid-glass background effect
Exec=/usr/local/bin/niri-glass-session
Type=WaylandSession
DesktopNames=niri
EOF

cat <<'EOF'

Done! Pick which version to launch at session start:

  exec /usr/local/bin/niri-glass-session   # liquid-glass version
  exec /usr/bin/niri-session             # pacman version

niri-glass reads ~/.config/niri/glass.kdl (your config.kdl + liquid glass).
Tweak the glass there; stock niri keeps using config.kdl untouched.


If you dont need liquid-glass anymore run:
  ./uninstall.sh

EOF
