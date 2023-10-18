{
  description = "A very basic flake";
  inputs= {
    # nixpkgs.url = "github:numtide/nixpkgs-unfree";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
      flake-utils.lib.eachDefaultSystem
      (system:
        let 
            pkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                segger-jlink.acceptLicense = true;
              };
            };
            pp = pkgs.python3.pkgs;
            imgtool = pp.buildPythonPackage rec {
              version = "1.10.0";
              pname = "imgtool";

              src = pp.fetchPypi {
                inherit pname version;
                sha256 = "sha256-A7NOdZNKw9lufEK2vK8Rzq9PRT98bybBfXJr0YMQS0A=";
              };

              propagatedBuildInputs = with pp; [
                cbor2
                click
                intelhex
                cryptography
              ];
              doCheck = false;
              pythonImportsCheck = [
                "imgtool"
              ];
            };

            python-packages = pkgs.python3.withPackages (p: with p; [
              autopep8
              pyelftools
              pyyaml
              pykwalify
              canopen
              packaging
              progress
              psutil
              anytree
              intelhex
              west
              imgtool

              cryptography
              intelhex
              click
              cbor2

              # For mcuboot CI
              toml

              # For twister
              tabulate
              ply

              # For TFM
              pyasn1
              graphviz
              jinja2

              requests
              beautifulsoup4

              # These are here because pip stupidly keeps trying to install
              # these in /nix/store.
              wcwidth
              sortedcontainers
            ]);

            # Build the Zephyr SDK as a nix package.
            new-zephyr-sdk-pkg =
              { stdenv
              , fetchurl
              , which
              , python38
              , wget
              , file
              , cmake
              , libusb
              , autoPatchelfHook
              }:
              let
                version = "0.15.0";
                arch = "arm";
                sdk = fetchurl {
                  url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/zephyr-sdk-${version}_linux-x86_64_minimal.tar.gz";
                  hash = "sha256-dn+7HVBtvDs2EyXSLMb12Q+Q26+x6HYyPP69QdLKka8=";
                };
                armToolchain = fetchurl {
                  url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/toolchain_linux-x86_64_arm-zephyr-eabi.tar.gz";
                  hash = "sha256-B7YIZEyuqE+XNI7IWnN6WiC1k9UdFEt4YN4Yr7Vn3Po=";
                };
                x86_64Toolchain = fetchurl {
                  url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/toolchain_linux-x86_64_x86_64-zephyr-elf.tar.gz";
                  hash = "sha256-9PoILowiS8wgfB/vdrpJUostIMyS62jjd21nRzWBQ/k=";
                };
              in
              stdenv.mkDerivation {
                name = "zephyr-sdk";
                inherit version;
                srcs = [ sdk armToolchain x86_64Toolchain ];
                srcRoot = ".";
                nativeBuildInputs = [
                  which
                  wget
                  file
                  python38
                  autoPatchelfHook
                  cmake
                  libusb
                ];
                phases = [ "installPhase" "fixupPhase" ];
                installPhase = ''
                  runHook preInstall
                  echo out=$out
                  mkdir -p $out
                  set $srcs
                  tar -xf $1 -C $out --strip-components=1
                  tar -xf $2 -C $out
                  tar -xf $3 -C $out
                  (cd $out; bash ./setup.sh -h)
                  rm $out/zephyr-sdk-x86_64-hosttools-standalone-0.9.sh
                  runHook postInstall
                '';
              };
            zephyr-sdk = pkgs.callPackage new-zephyr-sdk-pkg { };

            packages = with pkgs; [
              # Tools for building the languages we are using
              llvmPackages_16.clang-unwrapped # Newer than base clang, includes clang-format options Zephyr uses
              gcc_multi
              glibc_multi

              # Dependencies of the Zephyr build system.
              (python-packages)
              cmake
              ninja
              gperf
              python3
              ccache
              dtc
              gmp.dev

              zephyr-sdk

              nrfutil
              # nRF-Command-Line-Tools
              segger-jlink
              teensy-loader-cli
              tytools
              stlink

              picocom
              minicom
            ];
          in {
            devShells.default = 
              pkgs.mkShell {
                nativeBuildInputs = [ packages ];

                # For Zephyr work, we need to initialize some environment variables,
                # and then invoke the zephyr setup script.
                shellHook = ''
                  export ZEPHYR_SDK_INSTALL_DIR=${zephyr-sdk}
                  export PATH=$PATH:${zephyr-sdk}/arm-zephyr-eabi/bin
                  unset CFLAGS
                  unset LDFLAGS
                  source ./workspace/zephyr/zephyr-env.sh
                '';
              };

  });
}
