{
  description = "Python 3.11 and CUDA 12.8 environment for SOF";

  inputs = {
    # We must use unstable to access CUDA 12.8+ and PyTorch 2.7+ 
    # Older stable branches do not have the required binaries for the RTX 5080
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
            cudaVersion = "12.8"; # REQUIRED for RTX 50-series GPUs
          };
        };
        # Disable these doctests because cpython broke them
        # This flake uses python 3.11.15 which is not hardcoded and skipped
        # Keep in mind this package was last updatedi
        # Snipped pulled from the error message:
        # @pytest.mark.xfail(
        #   python_version() in ('3.11.9', '3.11.10', '3.11.11', '3.12.3'),
        #   reason='broken by https://github.com/python/cpython/pull/115440')
        customPython = pkgs.python311.override {
          packageOverrides = final: prev: {
            pytest-doctestplus = prev.pytest-doctestplus.overridePythonAttrs (old: {
              # This is the safe thing to do right?
              doCheck = false;
            });
            mirakuru = prev.mirakuru.overridePythonAttrs (old: {
              disabledTests = (old.disabledTests or []) ++ [
                "test_stop_custom_exit_signal_context"
              ];
            });
          };
        };
        pythonPackages = customPython.pkgs;
        cudaToolkit = pkgs.cudaPackages_12_8.cudatoolkit;

        open3d = import ./nix/open3d.nix {
          inherit pkgs pythonPackages;
        };

        gputil = import ./nix/gputil.nix {
          inherit pythonPackages;
        };

        diffGaussianRasterization = import ./nix/diff-gaussian-rasterization.nix {
          inherit pkgs cudaToolkit pythonPackages;

          srcPath = ./submodules/diff-gaussian-rasterization;
        };

        simpleKNN = import ./nix/simple-knn.nix {
          inherit pkgs cudaToolkit pythonPackages;

          srcPath = ./submodules/simple-knn;
        };

        tetraTriangulation = import ./nix/tetra-triangulation.nix {
          inherit pkgs cudaToolkit pythonPackages;

          srcPath = ./submodules/tetra-triangulation;
        };
        
        pythonEnv = customPython.withPackages (ps: with ps; [
          # top level environment.yml dependencies
          plyfile
          dacite
          torch-bin
          tqdm

          # pip install portion in environment.yml
          # No need to install ninja. Is for building the submodules
          #   which nix handles
          open3d
          # ninja
          gputil
          opencv-python
          trimesh
          einops
          scikit-image

          # submodule install portion
          diffGaussianRasterization
          simpleKNN
          tetraTriangulation

          # extras that are probably needed
          numpy
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          name = "cuda12.8-py3.11";

          buildInputs = [
            pythonEnv
            cudaToolkit
            pkgs.stdenv.cc.cc.lib
            pkgs.ruff
            pkgs.ty
          ];

          shellHook = ''
            export CUDA_PATH=${cudaToolkit}
            export LD_LIBRARY_PATH=/run/opengl-driver/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.libGL}/lib:$LD_LIBRARY_PATH

            echo "==================================================="
            echo "🚀 RTX 5080 / CUDA 12.8 & Python 3.12 loaded!"
            echo "==================================================="
            
            python -c "import torch; print(f'PyTorch Version: {torch.__version__}'); print(f'CUDA Available:  {torch.cuda.is_available()}')"
          '';
        };
      }
    );
}
