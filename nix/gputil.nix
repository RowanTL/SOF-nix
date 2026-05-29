{ pythonPackages }:

pythonPackages.buildPythonPackage rec {
  pname = "gputil";
  version = "1.4.0";
  pyproject = true;

  src = pythonPackages.fetchPypi {
    pname = "GPUtil";
    inherit version;
    sha256 = "sha256-CZ5Sxl5RLN+oyHY/ymf1pcKvtjRpYC1dy00pazZh77k=";
  };

  build-system = [
    pythonPackages.setuptools
  ];

  dependencies = [ ];

  # This phase tests that the module actually loads successfully post-install
  pythonImportsCheck = [ "GPUtil" ];
}
