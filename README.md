# Liquid Glass for Niri

A liquid-glass / refraction background effect for the [niri](https://github.com/niri-wm/niri)
Wayland compositor. Fork of [zaroutt/Niri-glass](https://github.com/zaroutt/Niri-glass); shader
based on [kwin-effects-glass](https://github.com/4v3ngR/kwin-effects-glass).

<img width="1920" height="1080" alt="Liquid glass windows on niri" src="https://github.com/user-attachments/assets/a10b40c7-b147-4dfa-8208-28ebb4003cfc" />

Built against niri 26.04 (rev `49fc611`). Other niri versions will not build.

## Changes in this fork

- **No more log flood.** Removed two debug warnings that were written every frame for every glass window.
- **`edge-padding` works.** It used to cut a see-through band into the window edges.
- **Xray mode refracts around the window, not the screen.** Refraction direction, lens dome and
  offset size were measured against the whole screen. With xray on, glass now looks the same wherever
  the window is. It may look weaker than before: raise `refraction-strength` if so.
- **Client-requested blur works again in xray mode.** It was being cut to the window rectangle.
- **Removed 7 options that did nothing:** `refraction-a/b/c/d`, `glow-bias`, `glow-edge0/1`.
  Delete them from your config, or it will fail to load.
- **Own config file.** niri-glass reads `~/.config/niri/glass.kdl`, which includes your normal
  `config.kdl`. Stock niri can't parse `liquid-glass`, so it stays out of your main config.
- **`install.sh` checks the niri version** before copying files over it.
- Internal cleanup: one shared list of shader values instead of four copies (−230 lines).

## Install

### install.sh (any distro with niri installed)

```bash
git clone https://github.com/niri-wm/niri
git -C niri checkout 49fc6117fd6c043adaa2ead316b82db5ed735d36
git clone https://github.com/leghawq-tech/Niri-glass
cd Niri-glass
./install.sh ../niri
```

This adds a "Niri (Liquid Glass)" session to your login manager and creates
`~/.config/niri/glass.kdl` (only if it doesn't exist yet). Remove it all with `./uninstall.sh`.

### Nix

```bash
nix run github:leghawq-tech/Niri-glass      # try without installing
```

NixOS:

```nix
inputs.niri-glass.url = "github:leghawq-tech/Niri-glass";
# in your modules:
imports = [ inputs.niri-glass.nixosModules.default ];
programs.niri-glass.enable = true;
```

A home-manager module (`homeManagerModules.default`) and an overlay (`pkgs.niri-glass`) are also
available. Nix does not set up `glass.kdl`; put the `liquid-glass` rule in your niri config.

## Configuration

`~/.config/niri/glass.kdl`:

```kdl
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
```

For a frosted look: `saturation 0.9`, `vibrancy 0.2`, `adaptive-dim 0.25`, `adaptive-boost 0.25`.

| Option | Default | What it does |
|---|---|---|
| `refraction-strength` | 1.0 | How strongly the edges bend the background (0–100, 0 turns the effect off) |
| `power-factor` | 3 | How sharply the bend falls off from the edge (1–10) |
| `refraction-power` | 0.6 | Bevel intensity in physical mode |
| `physical-refraction` | 0 | 0 = kwin-style edge refraction, 1 = refraction toward the window center |
| `edge-thickness` | 0.15 | Width of the refracting edge, as a fraction of the window size |
| `edge-padding` | 0 | Non-xray only: also sample content just outside the window |
| `fringing` | 0.3 | RGB color split at the edges |
| `edge-lighting` | 1.0 | Blends background colors into the edges |
| `glow-weight` | 0.08 | Edge glow and highlight strength |
| `lens-distortion` | 0.5 | Dome magnification in the middle of the window |
| `refraction-dilute` | 0 | Above 0: softer averaged refraction instead of the modes above |
| `dilute-strength` | 0 | Strength for dilute mode |
| `dilute-fringing` | 0 | Color split for dilute mode |
| `brightness` | 1.0 | Multiplies the glass color (0–1) |
| `contrast` | 1.0 | 1 = unchanged, lower = flatter |
| `saturation` | 0.85 | 1 = unchanged, lower = grayer |
| `vibrancy` | 0.12 | Boosts already-colorful areas |
| `adaptive-dim` | 0 | Darkens bright backgrounds |
| `adaptive-boost` | 0 | Lightens dark backgrounds |

## Warnings

- Only builds against niri 26.04 (`49fc611`).
- Vibe-coded project: expect weird behavior.
