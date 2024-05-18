{
  description = "Packaging depthai with nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
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
          src = pkgs.fetchFromGitHub {
            name = "libnop";
            owner = "luxonis";
            repo = "libnop";
            rev = "ab842f51dc2eb13916dc98417c2186b78320ed10";
            hash = "sha256-d2z/lDI9pe5TR82MxGkR9bBMNXPvzqb9Gsd5jOv6x1A=";
          };

          hardeningDisable = ["all"];
          buildInputs = [
            pkgs.gtest
          ];

          installPhase = ''
            mkdir $out
            cp -r include $out
          '';
        };

        xlink = pkgs.stdenv.mkDerivation {
          name = "XLink";
          src = pkgs.fetchFromGitHub {
            name = "xlink";
            owner = "luxonis";
            repo = "XLink";
            rev = "e9eb1ef38030176ad70cddd3b545d5e6c509f1e1";
            hash = "sha256-D0aKNni8LDqlWtllHwS/BQ2BGdB1GN1k9BDgjEgjEYM=";
          };

          buildInputs = [
            pkgs.cmake
          ];
        };
      in rec {
        packages.depthai = pkgs.stdenv.mkDerivation {
          name = "depthai";
          version = "2.25.1";

          srcs = [
            (pkgs.fetchFromGitHub {
              name = "depthai-core";
              owner = "luxonis";
              repo = "depthai-core";
              rev = "v2.25.1";
              hash = "sha256-jcuuUH+UMgQaNNnY6tpoA4rj0vq/pXcN+0gB11Ucx4A=";
            })
          ];

          sourceRoot = "depthai-core";

          nativeBuildInputs = with pkgs; [
            git
            cmake
            lomiri.cmake-extras
            pkg-config
          ];

          buildInputs = with pkgs; [
            bzip2
            lzma
            spdlog
            zlib
            libarchive
            fp16
            nlohmann_json
            libnop
            xlink
          ];

          cmakeFlags = [
            "-DHUNTER_ENABLED=Off"
            "-DDDEPTHAI_ENABLE_BACKWARD=Off"
          ];
        };

        packages.default = self.packages.${system}.depthai;

        devShell = pkgs.mkShell {
          inputsFrom = [packages.depthai];

          nativeBuildInputs = with pkgs; [
            cmakeWithGui
          ];
          # nativeBuildInputs = with pkgs; [
          #   cmake
          #   pkg-config
          # ];

          # buildInputs = with pkgs; [
          #   bzip2
          # ];
        };
      }
    );
}
