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

        # archive = pkgs.stdenv.mkDerivation {
        #   name = "archive";
        #   src = pkgs.fetchFromGitHub {
        #     name = "archive-luxonis";
        #     owner = "luxonis";
        #     repo = "libarchive";
        #     rev = "45baa3a3e57104519e1165bcd5ac29c3bd8c9f3a";
        #     hash = "sha256-6KTBpL1ibQAwRdzcan+qPhV5cNPHlxwhPJ+swOwJ92g=";
        #   };

        #   nativeBuildInputs = [
        #     pkgs.cmake
        #   ];
        # };
      in rec {
        packages.depthai =
          pkgs
          .stdenv
          .mkDerivation {
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
              # fp16
            ];

            cmakeFlags = [
              "-DHUNTER_ENABLED=Off"
            ];
          };

        packages.default = self.packages.${system}.depthai;

        devShell = pkgs.mkShell {
          inputsFrom = [packages.depthai];

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
