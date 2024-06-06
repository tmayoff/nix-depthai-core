{
  description = "Packaging depthai with nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs_21.url = "github:nixos/nixpkgs/nixos-21.05";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs_21,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs_21 = import nixpkgs_21 {
          inherit system;
        };

        overlays = [
          (final: prev: {
            fmt = prev.fmt.overrideAttrs (old: {
              version = "7.0.3";
              src = final.fetchFromGitHub {
                owner = "fmtlib";
                repo = "fmt";
                rev = final.fmt.version;
                sha256 = "sha256-Ks3UG3V0Pz6qkKYFhy71ZYlZ9CPijO6GBrfMqX5zAp8=";
              };
            });

            spdlog = pkgs_21.spdlog;
          })
        ];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        fp16 = pkgs.stdenv.mkDerivation {
          name = "FP16";
          srcs = [
            (
              pkgs.fetchFromGitHub {
                name = "PSIMD";
                owner = "Maratyszcza";
                repo = "psimd";
                rev = "072586a71b55b7f8c584153d223e95687148a900";
                hash = "sha256-lV+VZi2b4SQlRYrhKx9Dxc6HlDEFz3newvcBjTekupo=";
              }
            )
            (pkgs.fetchFromGitHub {
              name = "FP16";
              owner = "luxonis";
              repo = "FP16";
              rev = "c911175d2717e562976e606c6e5f799bf40cf94e";
              hash = "sha256-4U5WmqqljHYoKdKqtFRBX++vGCv/3weuqPFr4WG7GNM=";
            })
          ];

          sourceRoot = ".";

          cmakeFlags = [
            "-S/build/FP16"
            "-DPSIMD_SOURCE_DIR=/build/PSIMD"
            "-DFP16_BUILD_BENCHMARKS=OFF"
            "-DFP16_BUILD_TESTS=OFF"
          ];

          nativeBuildInputs = [
            pkgs.cmake
          ];
        };

        libnop = pkgs.stdenv.mkDerivation {
          name = "libnop";

          src = pkgs.fetchurl {
            url = "https://github.com/luxonis/libnop/archive/ab842f51dc2eb13916dc98417c2186b78320ed10.tar.gz";
            hash = "sha256-eOrFGEJ/6jW6uGe7Mil7MMX/cwttMntlh1l+jWuoEK8=";
          };

          hardeningDisable = ["all"];
          nativeBuildInputs = [pkgs.cmake pkgs.pkg-config];
          buildInputs = [pkgs.gtest];
          cmakeFlags = ["-DCMAKE_INSTALL_LIBDIR=lib"];
        };

        xlink = pkgs.stdenv.mkDerivation {
          name = "xlink";
          src = pkgs.fetchFromGitHub {
            name = "xlink";
            owner = "luxonis";
            repo = "XLink";
            rev = "e9eb1ef38030176ad70cddd3b545d5e6c509f1e1";
            hash = "sha256-D0aKNni8LDqlWtllHwS/BQ2BGdB1GN1k9BDgjEgjEYM=";
          };
          nativeBuildInputs = [
            pkgs.cmake
            pkgs.pkg-config
          ];

          buildInputs = [
            pkgs.libusb
          ];

          cmakeFlags = [
            "-DHUNTER_ENABLED=false"
            "-DXLINK_LIBUSB_SYSTEM=true"
          ];
        };

        artifacts_base_url = "https://artifacts.luxonis.com/artifactory";
        bootloader_version = "0.0.24";
        device_side_commit = "8c3d6ac1c77b0bf7f9ea6fd4d962af37663d2fbd";

        bootloader_filename = "depthai-bootloader-fwp-${bootloader_version}.tar.xz";
        device_side_filename = "depthai-device-fwp-${device_side_commit}.tar.xz";

        firmware = pkgs.fetchurl {
          name = "depthai-fwp";
          url = "${artifacts_base_url}/luxonis-myriad-snapshot-local/depthai-device-side/${device_side_commit}/${device_side_filename};unpack=0;name=device-fwp";
          hash = "sha256-ewNrmrG1wg033/1Jd8y+HEO1Tb93Ciq7zc/T1P/fBLE=";
        };
        # https://artifacts.luxonis.com/artifactory/luxonis-myriad-release-local/depthai-bootloader/0.0.17/depthai-bootloader-fwp-0.0.17.tar.xz
        bootloader = pkgs.fetchurl {
          name = "depthai-bootloader";
          url = "${artifacts_base_url}/luxonis-myriad-release-local/depthai-bootloader/${bootloader_version}/${bootloader_filename};unpack=0;name=bootloader-fwp";
          hash = "sha256-yRPGNshmUuqW7aITWlF2IPfVKNY1fdxpft+iB2KnyzA=";
        };
      in {
        packages.depthai = pkgs.stdenv.mkDerivation {
          name = "depthai";
          version = "2.25.1";

          src = pkgs.fetchzip {
            name = "depthai-core";
            url = "https://github.com/luxonis/depthai-core/releases/download/v2.25.1/depthai-core-v2.25.1.tar.gz";
            hash = "sha256-lsQzdkUz2Soil49CnXHfF/h7M0iFOjnx7W/xzOBAKzE=";
          };

          # src = pkgs.fetchFromGitHub {
          #   name = "depthai-core";
          #   owner = "luxonis";
          #   repo = "depthai-core";
          #   rev = "v2.25.1";
          #   hash = "sha256-jcuuUH+UMgQaNNnY6tpoA4rj0vq/pXcN+0gB11Ucx4A=";
          # };

          patches = [
            ./patches/deps.patch
            ./patches/001-maincmake.patch
          ];

          nativeBuildInputs = with pkgs; [
            # git
            cmake
            pkg-config
          ];

          buildInputs = with pkgs; [
            bzip2
            lzma
            spdlog
            zlib
            libarchive
            fp16
          ];

          propagatedBuildInputs = with pkgs; [
            libnop
            nlohmann_json
            xlink

            # Optional features
            opencv
            pcl
          ];

          cmakeFlags = [
            "-DBUILD_SHARED_LIBS=ON"
            "-DHUNTER_ENABLED=Off"
            "-DDEPTHAI_ENABLE_BACKWARD=Off"
            "-DDEPTHAI_BINARIES_RESOURCE_COMPILE=ON"
            "-DDEPTHAI_BOOTLOADER_FWP=${bootloader}"
            "-DDEPTHAI_DEVICE_FWP=${firmware}"
          ];
        };

        packages.default = self.packages.${system}.depthai;
      }
    );
}
