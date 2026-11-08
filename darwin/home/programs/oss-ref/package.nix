{
  lib,
  python3Packages,
  git,
  makeWrapper,
}:
python3Packages.buildPythonApplication {
  pname = "oss-ref";
  version = "0.1.0";
  pyproject = true;
  src = ./.;

  build-system = [ python3Packages.setuptools ];
  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram "$out/bin/oss-ref" --prefix PATH : ${lib.makeBinPath [ git ]}
  '';

  meta.mainProgram = "oss-ref";
}
