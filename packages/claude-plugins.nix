{ lib
, stdenv
, bun
, nodejs
, src
}:

stdenv.mkDerivation rec {
  pname = "claude-plugins";
  version = "0.2.0";

  inherit src;

  nativeBuildInputs = [ bun nodejs ];

  sourceRoot = "source/packages/cli";

  postPatch = ''
    # Apply giget patch to fix fetch import issue
    # Changes from ES6 import to CommonJS require for compatibility
    if [ -f node_modules/giget/dist/shared/giget.OCaTp9b-.mjs ]; then
      sed -i "s/import { fetch } from 'node-fetch-native\/proxy';/const {fetch} = require('node-fetch-native\/proxy');/" \
        node_modules/giget/dist/shared/giget.OCaTp9b-.mjs
    fi
  '';

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

        mkdir -p $out/bin $out/lib/claude-plugins

        cp -r dist $out/lib/claude-plugins/
        cp -r node_modules $out/lib/claude-plugins/
        cp package.json $out/lib/claude-plugins/

        cat > $out/bin/claude-plugins <<EOF
    #!${stdenv.shell}
    exec ${bun}/bin/bun $out/lib/claude-plugins/dist/index.js "\$@"
    EOF
        chmod +x $out/bin/claude-plugins

        runHook postInstall
  '';

  meta = with lib; {
    description = "CLI tool for managing Claude Code plugins";
    homepage = "https://github.com/Kamalnrf/claude-plugins";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "claude-plugins";
  };
}
