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
              udev
              
              # Core C-libraries required by PyTorch and PyPI wheels
              stdenv.cc.cc.lib
              zlib
              glib
              libGL

              # Graphics & Windowing libraries
              xorg.libX11
              xorg.libXext
              xorg.libXrender
              libxkbcommon
            ];

            shellHook = ''
              export CUDA_HOME=${pkgs.cudaPackages_12_8.cudatoolkit}
              export CC=${pkgs.gcc13}/bin/gcc
              export CXX=${pkgs.gcc13}/bin/g++
              
              export TORCH_CUDA_ARCH_LIST="8.9;9.0" 

              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath (with pkgs; [
                stdenv.cc.cc.lib
                zlib
                glib
                libGL
                xorg.libX11
                xorg.libXext
                xorg.libXrender
                libxkbcommon
                udev
              ])}:/run/opengl-driver/lib:${pkgs.linuxPackages.nvidia_x11}/lib:$LD_LIBRARY_PATH

              echo "==================================================="
              echo "🚀 Hybrid Nix + uv Sandbox Loaded!"
              echo "==================================================="
            '';
          };
        }
      );
    };
}
