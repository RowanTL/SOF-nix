{ pkgs, pythonPackages, cudaToolkit, srcPath }:

pythonPackages.buildPythonPackage {
  pname = "tetra-triangulation";
  version = "0.1.1";
  format = "setuptools";

  src = srcPath;

  # This forces Nix to skip the automated configurePhase so we 
  # can manually run cmake in our preBuild phase with the right compilers.
  dontUseCmakeConfigure = true;

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
    pkgs.which
    pkgs.pkg-config
    cudaToolkit
    pkgs.gcc13
    pkgs.autoPatchelfHook
  ];

  buildInputs = [
    pkgs.gmp
    pkgs.gmp.dev
    pkgs.cgal
    pkgs.mpfr
    pkgs.mpfr.dev
    pythonPackages.torch-bin
    pkgs.gcc13.cc.lib
  ];

  propagatedBuildInputs = [
    pythonPackages.trimesh # Required by setup.py
  ];

  preBuild = ''
    export CUDA_HOME=${cudaToolkit}
    export TORCH_CUDA_ARCH_LIST="12.0"
    export MAX_JOBS=8
    export CC=${pkgs.gcc13}/bin/gcc
    export CXX=${pkgs.gcc13}/bin/g++

    cmake . -DCMAKE_CUDA_COMPILER=${cudaToolkit}/bin/nvcc \
            -DCMAKE_CUDA_HOST_COMPILER=${pkgs.gcc13}/bin/g++ \
            -DCMAKE_CUDA_FLAGS="-I${cudaToolkit}/include -D_GLIBCXX_USE_CXX11_ABI=1" \
            -DCMAKE_CXX_FLAGS="-I${cudaToolkit}/include -D_GLIBCXX_USE_CXX11_ABI=1" \
            -DFETCHCONTENT_SOURCE_DIR_PYBIND11=${pythonPackages.pybind11.src} \
            -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
            -DGMP_INCLUDE_DIR=${pkgs.gmp.dev}/include \
            -DGMP_LIBRARIES=${pkgs.gmp}/lib/libgmp.so
    make -j$MAX_JOBS
  '';

  postPatch = ''
    echo "Surgically patching FindTorch.cmake to use ABI=1..."
    # Find the specific CMake script and flip the ABI flag to match PyTorch
    find . -name "FindTorch.cmake" -exec sed -i 's/-D_GLIBCXX_USE_CXX11_ABI=0/-D_GLIBCXX_USE_CXX11_ABI=1/g' {} +
  '';

  # this is vibe coded slop at this point
  postInstall = ''
    echo "Rescuing compiled C++ extension..."
    EXT_DIR=$out/lib/python${pythonPackages.python.pythonVersion}/site-packages/tetranerf/utils/extension
    
    # 1. Hunt down the compiled .so file
    SO_FILE=$(find . -name "*tetranerf_cpp_extension*.so" | head -n 1)
    
    # 2. If we didn't build it, fail the Nix build immediately!
    if [ -z "$SO_FILE" ]; then
      echo "💥 FATAL ERROR: CMake failed to produce the .so file!"
      exit 1
    fi
    
    echo "Found compiled extension at: $SO_FILE"
    
    # 3. Copy it and FORCE the exact name Python is looking for
    cp "$SO_FILE" "$EXT_DIR/tetranerf_cpp_extension.so"
    
    echo "Injecting PyTorch library path into RPATH..."
    TORCH_LIB="${pythonPackages.torch-bin}/lib/python${pythonPackages.python.pythonVersion}/site-packages/torch/lib"
    patchelf --add-rpath $TORCH_LIB "$EXT_DIR/tetranerf_cpp_extension.so"
  '';

  # Tell autoPatchelfHook to ignore PyTorch internals (they load dynamically at runtime)
  autoPatchelfIgnoreMissingDeps = [
    "libtorch_cpu.so"
    "libtorch.so"
    "libc10.so"
    "libcudart.so.12"
    "libc10_cuda.so"
    "libtorch_cuda.so"
  ];

  doCheck = false;
  
  # The setup.py finds the package "tetranerf", but the actual import 
  # might vary based on how they structured the folder. We skip the strict
  # import check here to avoid sandbox pathing issues.
}
