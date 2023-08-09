{
  description = "Flake used to setup development environment for Zephyr";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  # mach-nix used to create derivation for Python dependencies in the requirements.txt files
  inputs.mach-nix.url = "mach-nix/3.5.0";

  outputs = { self, nixpkgs, mach-nix }:
    let
      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

      # Read requirements files to get Python dependencies
      # mach-nix is not capable of using a requirements.txt with -r directives
      # Using list of requirements files: read each file, concatenate contents in single string
      requirementsFileList =  [ ./scripts/requirements-base.txt ./scripts/requirements-build-test.txt ./scripts/requirements-compliance.txt ./scripts/requirements-doc.txt ./scripts/requirements-extras.txt ./scripts/requirements-run-test.txt ];
      allRequirements = nixpkgs.lib.concatStrings (map (x: builtins.readFile x) requirementsFileList);
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};

          # Import SDK derivation
          zephyrSdk = import ./sdk.nix { inherit pkgs system; };

          # Create Python dependency derivation
          pyEnv = mach-nix.lib.${system}.mkPython { requirements = allRequirements; };
        in {
          default = pkgs.mkShell {
            # Combine all required dependencies into the buildInputs (system + Python + Zephyr SDK)
            buildInputs = with pkgs; [ cmake python39Full python39Packages.pip python39Packages.setuptools dtc git ninja gperf ccache dfu-util wget xz file gnumake gcc gcc_multi SDL2 pyEnv zephyrSdk ];

            # When shell is created, start with a few Zephyr related environment variables defined.
            shellHook = ''
              export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
              export ZEPHYR_SDK_INSTALL_DIR=${zephyrSdk}/${zephyrSdk.pname}-${zephyrSdk.version}
            '';
          };
        }
      );
    };
}
