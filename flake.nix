{
  description = "Nix Flake for BroTracker";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "BroTracker";
        version = "0.1.9";

        src = pkgs.fetchurl {
          url = "https://brotracker-prod.blr1.digitaloceanspaces.com/portal/brotracker-portal_0.1.9_amd64.deb";
          hash = "sha256-pskszeu6WqgvyeA+hhya7W3nyFZLnCo6MgKxkJ4Ad3c=";
        };

        nativeBuildInputs = with pkgs; [
          dpkg
          autoPatchelfHook
          makeWrapper
        ];

        # Standard Electron and X11/Wayland dependencies required by autoPatchelf
        buildInputs = with pkgs; [
          stdenv.cc.cc.lib
          cairo
          libX11
          libXcomposite
          libXdamage
          libXext
          libXfixes
          libXrandr
          mesa
          expat
          libxcb
          libxkbcommon
          alsa-lib
          rPackages.aspi
          vulkan-loader
          libGL
          nss
          nspr
          dbus
          atk
          at-spi2-atk
          cups
          gtk3
          pango
          systemd
        ];

        runtimeDependencies = with pkgs; [
          systemd # For libudev if needed by Electron
          vulkan-loader
        ];

        dontConfigure = true;
        dontBuild = true;

        unpackPhase = ''
          runHook preUnpack
          dpkg-deb -x $src .
          runHook postUnpack
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin $out/opt $out/share

          if [ -d "opt" ]; then
            cp -r opt/* $out/opt/
          fi
          [ -d usr/share ] && cp -r usr/share/* $out/share/

          BINARY_PATH=$(find $out/opt -type f -executable | head -n 1)

          if [ -z "$BINARY_PATH" ]; then
            echo "Error: Could not find any executable binary under opt/"
            exit 1
          fi

          makeWrapper "$BINARY_PATH" $out/bin/brotracker \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.runtimeDependencies}"

          for f in $out/share/applications/*.desktop; do
            if [ -f "$f" ]; then
              substituteInPlace "$f" \
                --replace-quiet "/opt/" "$out/opt/"
            fi
          done

          runHook postInstall
        '';

        meta = {
          description = "BroTracker desktop app";
          platforms = [ "x86_64-linux" ];
          mainProgram = "brotracker";
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        };
      });
    };
}
