{
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  bzip2,
}:
stdenv.mkDerivation {
  name = "depthai";
  version = "2.25.1";

  srcs = [
    (fetchFromGitHub {
      name = "depthai-core";
      owner = "luxonis";
      repo = "depthai-core";
      rev = "v2.25.1";
      hash = "sha256-jcuuUH+UMgQaNNnY6tpoA4rj0vq/pXcN+0gB11Ucx4A=";
    })
  ];

  sourceRoot = "depthai-core";

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    bzip2
  ];

  cmakeFlags = [
    "-DHUNTER_ENABLED=Off"
    "-DBUILD_SHARED_LIBS=ON"
  ];
}
