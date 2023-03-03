{ pkgs ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz) {} }:

let
  molecule = pkgs.python39Packages.buildPythonPackage rec {
    pname = "molecule";
    version = "3.5.2";

    src = pkgs.python39Packages.fetchPypi {
        inherit pname version;
        sha256 = "yCrwmeXAmY1+sWo79l7VpO3Zfjgk+5OM4BvwZKRs4Mo=";
    };

    propagatedBuildInputs = with pkgs.python39Packages; [ 
        ansible 
        ansible-core 
        ansible-lint
        gevent
        geoip2
        setuptools
        setuptools-scm
        libselinux
        pyyaml
        click-help-colors
        pkgs.selinux-python
    ];

    doCheck = false;
  };

  ansiblePython = pkgs.python39.buildEnv.override {
    extraLibs = [ molecule ];
  };
in

pkgs.mkShell {
  buildInputs = [ ansiblePython ];
}
