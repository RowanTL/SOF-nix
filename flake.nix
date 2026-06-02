{
  description = "Python uv environment with cuda packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs [ "x86_64-linux" ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
              cudaVersion = "12.8";
            };
          };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              python311
              uv
              ninja      # Required for compiling the submodules
              gcc13      # C++ Compiler
              cudaPackages_12_8.cudatoolkit
              colmapWithCuda
              
              # Core C-libraries required by PyTorch and PyPI wheels
              stdenv.cc.cc.lib
              zlib
              glib
              libGL
              udev

              # Graphics & Windowing libraries
              xorg.libX11
              xorg.libXext
              xorg.libXrender
              xorg.libxcb
              libxkbcommon
            ];

            shellHook = ''
              export CUDA_HOME=${pkgs.cudaPackages_12_8.cudatoolkit}
              export CC=${pkgs.gcc13}/bin/gcc
              export CXX=${pkgs.gcc13}/bin/g++
              
              export TORCH_CUDA_ARCH_LIST="8.9;9.0" 

              mkdir -p .nix-gpu-libs
              ln -sf /usr/lib/x86_64-linux-gnu/libcuda.so* .nix-gpu-libs/ 2>/dev/null || true
              ln -sf /usr/lib/x86_64-linux-gnu/libnvidia*.so* .nix-gpu-libs/ 2>/dev/null || true

              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath (with pkgs; [
                stdenv.cc.cc.lib
                zlib
                glib
                libGL
                xorg.libX11
                xorg.libXext
                xorg.libXrender
                xorg.libxcb
                libxkbcommon
                udev
              # ])}:/run/opengl-driver/lib:/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib:$LD_LIBRARY_PATH
              # ])}:/run/opengl-driver/lib:/usr/lib/wsl/lib:$LD_LIBRARY_PATH
              ])}:$PWD/.nix-gpu-libs:/run/opengl-driver/lib:/usr/lib/wsl/lib:$LD_LIBRARY_PATH

              echo "==================================================="
              echo "🚀 Hybrid Nix + uv Sandbox Loaded!"
              echo "==================================================="
            '';
          };
        }
      );
    };
}
