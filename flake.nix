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

        # Libraries the binaries are linked against (autoPatchelfHook resolves these)
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

        # Libraries Electron/Chromium dlopen() at runtime. autoPatchelfHook adds
        # these to the RPATH of every ELF it patches, so dlopen finds them.
        runtimeDependencies = with pkgs; [
          systemd # libudev
          vulkan-loader
          libGL
          libnotify
          libsecret
          libpulseaudio
          pipewire
        ];

        dontConfigure = true;
        dontBuild = true;

        # Prebuilt binaries: stripping is pointless and can damage Electron/native modules
        dontStrip = true;

        unpackPhase = ''
          runHook preUnpack
          dpkg-deb -x $src .
          runHook postUnpack
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin $out/opt $out/share

          if [ -d opt ]; then
            cp -r opt/* $out/opt/
          fi
          if [ -d usr/share ]; then
            cp -r usr/share/* $out/share/
          fi

          # Pick the real Electron binary deterministically: the largest executable
          # that is not a shared object or one of Chromium's helper binaries.
          # (`find | head -n 1` returns whatever the filesystem lists first.)
          BINARY_PATH=$(
            find $out/opt -type f -executable \
              ! -name '*.so*' \
              ! -name 'chrome-sandbox' \
              ! -name 'chrome_crashpad_handler' \
              -printf '%s\t%p\n' | sort -rn | head -n 1 | cut -f2-
          )

          if [ -z "$BINARY_PATH" ]; then
            echo "Error: Could not find the main executable under opt/"
            exit 1
          fi
          echo "Wrapping main binary: $BINARY_PATH"

          makeWrapper "$BINARY_PATH" $out/bin/brotracker \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.runtimeDependencies}" \
            --prefix PATH : "${lib.makeBinPath [ pkgs.xdg-utils ]}"

          # Point the launcher entry at the *wrapper*, not the raw binary, so that
          # launching from the app menu behaves exactly like running `brotracker`.
          # Trailing arguments (%U, --no-sandbox, ...) are preserved.
          for f in $out/share/applications/*.desktop; do
            [ -f "$f" ] || continue
            sed -i -E 's#^Exec=("[^"]*"|[^ ]+)#Exec=brotracker#' "$f"
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

      apps.${system}.default = {
        type = "app";
        program = lib.getExe self.packages.${system}.default;
      };
    };
}
