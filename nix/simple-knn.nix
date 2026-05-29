{ pkgs, pythonPackages, cudaToolkit, srcPath }:

pythonPackages.buildPythonPackage {
  pname = "simple-knn";
  version = "0.0.1";
  format = "setuptools";

  src = srcPath;

  # Inject the missing float header for FLT_MAX
  postPatch = ''
    sed -i '1i#include <cfloat>' simple_knn.cu
  '';

  nativeBuildInputs = [
    pkgs.ninja
    pkgs.which
    cudaToolkit
    pkgs.gcc13
  ];

  buildInputs = [
    pythonPackages.torch-bin
    pkgs.gcc13.cc.lib
  ];

  preBuild = ''
    export CUDA_HOME=${cudaToolkit}
    export TORCH_CUDA_ARCH_LIST="12.0"
    export MAX_JOBS=8
    
    export CC=${pkgs.gcc13}/bin/gcc
    export CXX=${pkgs.gcc13}/bin/g++
  '';

  doCheck = false;
  pythonImportsCheck = [ "simple_knn" ];
}
