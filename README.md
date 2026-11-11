# BroTracker Nix Flake

❄️ A Nix flake that packages and runs the **BroTracker** desktop application (`brotracker-portal`, v0.1.12) on **NixOS**.

## Features

- **Declarative extraction:** Downloads the official `.deb` release using `fetchurl`, pinned by a SHA-256 hash, and extracts it using `dpkg-deb` for reproducible packaging.
- **Automatic library patching:** Uses `autoPatchelfHook` to resolve shared library dependencies required by the prebuilt Electron application, including GTK3, NSS, X11, Mesa, Vulkan and related libraries.
- **Wayland support:** The `brotracker` wrapper automatically adds `--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations` when both `NIXOS_OZONE_WL` and `WAYLAND_DISPLAY` are set.
- **Desktop integration:** Includes desktop entries and application icons from the original Debian package. Updates launcher commands to use the Nix-managed `brotracker` executable, making the application accessible through launchers such as Rofi, Hyprland menus and GNOME.
- **Runtime libraries:** Includes additional runtime dependencies such as `libudev`, Vulkan, libnotify, libsecret, PulseAudio and PipeWire through the application wrapper.

> **Platform:** `x86_64-linux` only. This package uses a prebuilt binary (`binaryNativeCode`) rather than compiling the application from source.

---

## Installation & Usage

### 1. Run without installing

Run the application directly using Nix:

```bash
nix run github:myselfanandvp/brotracker-flake
```

Alternatively, run it from a local checkout:

```bash
nix run .
```

### 2. Install on NixOS

Add the flake as an input in your system's `flake.nix`:

```nix
{
  inputs.brotracker.url = "github:myselfanandvp/brotracker-flake";
}
```

Add the package to your NixOS configuration:

```nix
environment.systemPackages = [
  inputs.brotracker.packages.${pkgs.system}.default
];
```

Make sure the flake inputs are passed to your NixOS modules, for example:

```nix
specialArgs = {
  inherit inputs;
};
```

Apply the configuration:

```bash
sudo nixos-rebuild switch --flake .#yourHostName
```

### 3. Install using Home Manager

If you manage your user packages through Home Manager, add the package to your `home.packages`:

```nix
home.packages = [
  inputs.brotracker.packages.${pkgs.system}.default
];
```

Make sure your Home Manager configuration receives the flake inputs through `extraSpecialArgs`:

```nix
extraSpecialArgs = {
  inherit inputs;
};
```

Apply the Home Manager configuration:

```bash
home-manager switch --flake .#yourUsername
```

---

## Package Details

| Field | Value |
|---|---|
| Application | BroTracker |
| Package name | `brotracker-portal` |
| Version | `0.1.12` |
| Executable | `brotracker` |
| Package format | Debian (`.deb`) |
| Nixpkgs | `nixos-unstable` |
| Architecture | `x86_64-linux` |
| Packaging | Prebuilt binary |
| License | Inherited from the upstream application; not independently verified |

---

## Updating

When a new BroTracker release becomes available:

1. Update the package version in the Nix derivation.
2. Update the official `.deb` download URL.
3. Download the new package and calculate its Nix hash:

   ```bash
   nix hash file brotracker-portal.deb
   ```

4. Replace the existing hash with the new hash.
5. Build and test the package:

   ```bash
   nix build .#default
   ```

6. Commit and push the updated flake.

---

## Notes

- The package downloads the official BroTracker Debian release.
- The Nix derivation handles extraction, library patching, runtime dependencies and desktop integration.
- The original application is distributed as a prebuilt binary, so its source code is not compiled by this flake.
- Package availability depends on the upstream download URL remaining accessible.

## Repository

[GitHub: myselfanandvp/brotracker-flake](https://github.com/myselfanandvp/brotracker-flake)
