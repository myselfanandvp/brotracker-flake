{
  description = "Nix Flake for Workfolio";

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
          name = "brotracker-portal_0.1.9_amd64${finalAttrs.version}.deb";
          url = "https://brotracker-prod.blr1.digitaloceanspaces.com/portal/brotracker-portal_0.1.9_amd64.deb";
          hash = "N6w+OZvA5RReuzlzbLo0noL2a8kIQaGBvkPJmOCRANlRXS9I72Z3MXbMteyJb48qRvcjtF8LvbQLUAK6pD8oMQ==";
        };

        nativeBuildInputs = with pkgs; [
          dpkg
          autoPatchelfHook
          makeWrapper
        ];

        buildInputs = with pkgs; [
        ];

        # dlopen()'d at runtime, invisible to autoPatchelf's DT_NEEDED scan
        runtimeDependencies = with pkgs; [
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
          cp -r opt/BroTracker$out/opt/BroTracker
          [ -d usr/share ] && cp -r usr/share/* $out/share/

          makeWrapper $out/opt/BroTracker/brotracker$out/bin/brotracker\
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.runtimeDependencies}"

          # Fix .desktop file to point at the wrapper
          for f in $out/share/applications/*.desktop; do
            substituteInPlace "$f" \
              --replace-quiet "/opt/BroTracker/brotracker" "$out/bin/brotracker"
          done

          runHook postInstall
        '';

        meta = {
          description = "BroTracker desktop app";
          platforms = [ "x86_64-linux" ];
          mainProgram = "BroTracker";
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        };
      });
    };
}
