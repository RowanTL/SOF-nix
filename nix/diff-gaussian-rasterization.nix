{ pkgs, pythonPackages, cudaToolkit, srcPath }:

pythonPackages.buildPythonPackage {
  pname = "diff-gaussian-rasterization";
  version = "0.0.1";
  format = "setuptools";

  src = srcPath;

  # Apply the exact same cstdint patch as the _ms version
  postPatch = ''
    sed -i '1i#include <cstdint>' cuda_rasterizer/rasterizer_impl.h
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
  pythonImportsCheck = [ "diff_gaussian_rasterization" ];
}
