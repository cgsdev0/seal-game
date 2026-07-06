{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    godot-overlay.url = "github:florianvazelle/godot-overlay";
    godot-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self
    , flake-parts
    , nixpkgs
    , godot-overlay
    , ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          buildInputs = with pkgs; [
            libxext
            fontconfig
            pkg-config
            openssl
            wayland
            wayland-protocols
            libxkbcommon
            libx11
            libxcursor
            libxi
            libxrandr
            vulkan-loader
            vulkan-headers
            libGL
            alsa-lib
            libpulseaudio
            libdecor
            libxinerama
            dbus
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
        in
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [
              godot-overlay.overlays.default
            ];
          };

          devShells = {
            default = pkgs.mkShell {
              inherit LD_LIBRARY_PATH buildInputs;
              packages = with pkgs; [
                godotpkgs.latest
              ];
            };
          };

        };
    };
}
