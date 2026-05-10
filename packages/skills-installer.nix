{ lib
, stdenv
, buildNpmPackage
, bun
, src
}:

buildNpmPackage rec {
  pname = "skills-installer";
  version = "0.1.3";

  inherit src;

  nativeBuildInputs = [ bun ];

  sourceRoot = "source/packages/skills-installer";

  npmDepsHash = "sha256-JZ5LCTRj+WHDXy/67dle1MZ2S/nhO9ugEmCLuc6y78c=";
  npmFlags = [ "--workspaces=false" ];

  postPatch = ''
    cp ${./skills-installer.package-lock.json} package-lock.json
    chmod u+w package-lock.json
  '';

  preBuild = ''
    for file in node_modules/giget/dist/shared/giget.*.mjs; do
      if [ -f "$file" ]; then
        substituteInPlace "$file" \
          --replace-fail "import { fetch } from 'node-fetch-native/proxy';" \
          "const {fetch} = require('node-fetch-native/proxy');"
      fi
    done
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/skills-installer

    cp -r dist $out/lib/skills-installer/
    cp package.json $out/lib/skills-installer/

    cat > $out/bin/skills-installer <<EOF
    #!${stdenv.shell}
    exec ${bun}/bin/bun $out/lib/skills-installer/dist/cli.js "\$@"
    EOF
    chmod +x $out/bin/skills-installer

    runHook postInstall
  '';

  meta = with lib; {
    description = "Install agent skills across multiple AI coding clients";
    homepage = "https://github.com/Kamalnrf/claude-plugins";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "skills-installer";
  };
}
