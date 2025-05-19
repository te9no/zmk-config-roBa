{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
    packages = forAllSystems (system: rec {
      default = firmware;

      firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
        name = "firmware";

        src = nixpkgs.lib.sourceFilesBySuffices self [ ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi" ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig" ];

        board = "seeeduino_xiao_ble";
        shield = "roBa_%PART%";
        parts = [ "L" "R" ];
        enableZmkStudio = true;
        toolchain = "zephyr-full";
        snippets = [ "studio-rpc-usb-uart" ];

        nativeBuildInputs = with nixpkgs.legacyPackages.${system}; [
          protobuf
          dtc
          (python3.withPackages (ps: with ps; [
            setuptools
            protobuf
            pip
            grpcio
            grpcio-tools
          ]))
        ];

        zephyrDepsHash = "sha256-YkNPlLZcCguSYdNGWzFNfZbJgmZUhvpB7DRnj++XKqQ=";

        meta = {
          description = "ZMK firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
