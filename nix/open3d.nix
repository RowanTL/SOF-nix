{ pkgs, pythonPackages }:

pythonPackages.buildPythonPackage {
  pname = "open3d";
  version = "0.19.0";
  format = "wheel";

  # Notice the `cp312` in the filename for Python 3.12
  src = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/2b/95/3723e5ade77c234a1650db11cbe59fe25c4f5af6c224f8ea22ff088bb36a/open3d-0.19.0-cp312-cp312-manylinux_2_31_x86_64.whl"; 
    hash = "sha256-AeRZDcIgkEApLr5QlUL78r+GnqYLzZvno/53tlutMZI="; 
  };

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
  ];

  # Explicitly tell autoPatchelfHook to ignore the PyTorch/CUDA libraries
  # that Open3D will dynamically load at runtime.
  autoPatchelfIgnoreMissingDeps = [
    "libtorch_cpu.so"
    "libtorch.so"
    "libc10.so"
    "libcudart.so.12"
    "libc10_cuda.so"
    "libtorch_cuda.so"
  ];

  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    libGL
    glib
    zlib
    libx11
    libxext
    libxrender
    libusb1
  ];

  propagatedBuildInputs = with pythonPackages; [
    numpy
    matplotlib
    pandas
    scipy
    pyyaml
    tqdm
    scikit-learn
    ipywidgets
    addict
    werkzeug
    dash
    configargparse
    nbformat
    pyquaternion
  ];

  doCheck = false;
}
