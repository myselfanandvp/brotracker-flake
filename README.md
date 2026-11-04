# BroTracker Nix Flake

❄️ A Nix flake that packages and runs the **BroTracker** desktop app (`brotracker-portal`, v0.1.9) on **NixOS**.

---

## Features

* **Declarative extraction:** Downloads the official `.deb` release with `fetchurl` (pinned by hash) and unpacks it with `dpkg-deb`, so the build is reproducible.
* **Automatic library patching:** Uses `autoPatchelfHook` to link the Electron, GTK3, NSS, X11, Mesa, Vulkan and related shared libraries the prebuilt binary needs.
* **Wayland support:** The `brotracker` wrapper adds `--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations` automatically when `NIXOS_OZONE_WL` and `WAYLAND_DISPLAY` are set.
* **Desktop integration:** Copies `usr/share` (desktop entries, icons) into the package and rewrites `.desktop` paths from `/opt/` to the Nix store, so the app shows up in launchers such as Rofi, Hyprland menus and GNOME.
* **Runtime libraries:** `systemd` (libudev) and `vulkan-loader` are added to `LD_LIBRARY_PATH` in the wrapper.

> **Platform:** `x86_64-linux` only. The package is a prebuilt binary (`binaryNativeCode`), not built from source.

---

## Installation & Usage

### 1. Run without installing

```bash
nix run github:myselfanandvp/brotracker-flake
```

Or from a local checkout:

```bash
nix run .
```

### 2. Install on NixOS

Add the flake as an input in your system `flake.nix`:

```nix
{
  inputs.brotracker.url = "github:myselfanandvp/brotracker-flake";
}
```

Then add the package to your configuration:

```nix
environment.systemPackages = [
  inputs.brotracker.packages.${pkgs.system}.default
];
```

Make sure `inputs` is passed to your modules (for example via `specialArgs = { inherit inputs; };`).

Apply the change:

```bash
sudo nixos-rebuild switch --flake .#yourHostName
```

---

## Package details

| Field        | Value                            |
| ------------ | -------------------------------- |
| Package name | `BroTracker`                     |
| Version      | `0.1.9`                          |
| Binary       | `brotracker`                     |
| Nixpkgs      | `nixos-unstable`                 |
| System       | `x86_64-linux`                   |

---
