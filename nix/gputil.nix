{ pythonPackages }:

pythonPackages.buildPythonPackage rec {
  pname = "gputil";
  version = "1.4.0";
  pyproject = true;

  src = pythonPackages.fetchPipy {
    pname = "GPUtil";
    inherit version;
    sha256 = "";
  };

  build-system = [
    pythonPackages.setuptools
  ];

  dependencies = [ ];

  # This phase tests that the module actually loads successfully post-install
  pythonImportsCheck = [ "GPUtil" ];
}
