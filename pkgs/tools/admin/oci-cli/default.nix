# To build this:
# nix-build -K -E 'with import <nixpkgs> { }; callPackage ./default.nix {}' --show-trace
#
# Or to build using the same version of nixpkgs (reproducible build):
# nix-build -K shell.nix --show-trace

{ lib
, python
, pythonPackages
, fetchurl
, groff
, less
, gcc
, libffi
, openssl
}:

let
  py = python.override {
    packageOverrides = self: super: {

      python-dateutil = super.python-dateutil.overridePythonAttrs (oldAttrs: rec {
        version = "2.5.3";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "1408fdb07c6a1fa9997567ce3fcee6a337b39a503d80699e0f213de4aa4b32ed";
        };
      });

      cryptography = super.cryptography.overridePythonAttrs (oldAttrs: rec {
        version = "2.1.3";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "68a26c353627163d74ee769d4749f2ee243866e9dac43c93bb33ebd8fbed1199";
        };
      });

      pytz = super.pytz.overridePythonAttrs (oldAttrs: rec {
        version = "2016.10";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "aafbf066975fe217ed49d7d197b26903d3b43e9ca2aa6ba0a211081f13c41917";
        };
      });

      six = pythonPackages.buildPythonPackage rec {
        name = "six-1.11.0";
        src = fetchurl {
          url = "mirror://pypi/s/six/${name}.tar.gz";
          sha256 = "70e8a77beed4562e7f14fe23a786b54f6296e34344c23bc42f07b15018ff98e9";
        };
      };

      jmespath = pythonPackages.buildPythonPackage rec {
        name = "jmespath-0.9.3";

        src = fetchurl {
          url = "mirror://pypi/j/jmespath/${name}.tar.gz";
          sha256 = "6a81d4c9aa62caf061cb517b4d9ad1dd300374cd4706997aff9cd6aedd61fc64";
        };

        buildInputs = with self; [ nose ];
        propagatedBuildInputs = with self; [ ply ];

        meta = {
          homepage = https://github.com/boto/jmespath;
          description = "JMESPath allows you to declaratively specify how to extract elements from a JSON document";
          license = "BSD";
        };
      };

      httpsig-cffi = pythonPackages.buildPythonPackage rec {
        name = "httpsig-ffi-15.0.0";

        src = fetchurl {
          url = "https://pypi.python.org/packages/2b/26/09b2f9b962e821abb41a7b5d15b60aedeccfe68f7fafd2040617f0b27c29/httpsig_cffi-15.0.0.tar.gz";
          sha256 = "12b61008cd21cb18986de743959d63caaf8ac5b3cf3ee1d49fd1c53fe4f5d47a";
        };

        buildInputs = with self; [
          six
          cryptography
        ];
      };

      oci = pythonPackages.buildPythonPackage rec {
        name = "oci-1.3.17";

        src = fetchurl {
          url = "mirror://pypi/o/oci/${name}.tar.gz";
          sha256 = "93612ac4f7cd7e32047a1abbf36219c3539799a3f5f72322ff8b0d7a7959f597";
        };

        buildInputs = with self; [
          httpsig-cffi
          gcc
          libffi
          pythonPackages.cffi
          openssl
          cryptography
          python-dateutil
          pyopenssl
          requests
          configparser
          cffi
          pyjwt
          pytz
          six
        ];
        propagatedBuildInputs = with self; [ ply ];
      };
    };
  };
in py.pkgs.buildPythonApplication rec {
  pname = "oci-cli";
  version = "2.4.19";

  src = py.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "0rv7s97zg9bprlz9af09fjgcmyy65120h0n09x4ihkin40bgnfmr";
  };

  # No tests included
  doCheck = false;

  propagatedBuildInputs = with py.pkgs; [
    arrow
    certifi
    click
    configparser
    httpsig-cffi
    jmespath
    libffi
    oci
    openssl
    pyjwt
    pyopenssl
    python-dateutil
    pytz
    requests
    retrying
    terminaltables
  ];

  postInstall = ''
    mkdir -p $out/etc/bash_completion.d
    echo "complete -C $out/bin/oci_autocomplete.sh oci" > $out/etc/bash_completion.d/oci-cli
    #mkdir -p $out/share/zsh/site-functions
    #mv $out/bin/aws_zsh_completer.sh $out/share/zsh/site-functions
    #rm $out/bin/aws.cmd
  '';

  meta = with lib; {
    homepage = https://github.com/oracle/oci-cli;
    description = "Command Line Interface for Oracle Cloud Infrastructure";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}
