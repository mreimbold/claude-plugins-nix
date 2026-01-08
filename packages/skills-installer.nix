{ lib
, stdenv
, bun
, nodejs
, src
}:

stdenv.mkDerivation rec {
  pname = "skills-installer";
  version = "0.1.3";

  inherit src;

  nativeBuildInputs = [ bun nodejs ];

  sourceRoot = "source/packages/skills-installer";

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR
    bun install --frozen-lockfile --no-progress

    # Apply giget patch after install
    if [ -f node_modules/giget/dist/shared/giget.OCaTp9b-.mjs ]; then
      sed -i "s/import { fetch } from 'node-fetch-native\/proxy';/const {fetch} = require('node-fetch-native\/proxy');/" \
        node_modules/giget/dist/shared/giget.OCaTp9b-.mjs
    fi

    bun run build

    runHook postBuild
  '';

  installPhase = ''
        runHook preInstall

        mkdir -p $out/bin $out/lib/skills-installer

        cp -r dist $out/lib/skills-installer/
        cp -r node_modules $out/lib/skills-installer/
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
