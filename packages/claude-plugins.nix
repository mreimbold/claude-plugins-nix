{ lib
, stdenv
, buildNpmPackage
, bun
, src
}:

buildNpmPackage rec {
  pname = "claude-plugins";
  version = "0.2.0";

  inherit src;

  nativeBuildInputs = [ bun ];

  sourceRoot = "source/packages/cli";

  npmDepsHash = "sha256-FS8lBEWxU5jrelRilgfdKT16KIjm9oKna3LqFFOj5fg=";
  npmFlags = [ "--workspaces=false" ];

  postPatch = ''
    cp ${./claude-plugins.package-lock.json} package-lock.json
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

    mkdir -p $out/bin $out/lib/claude-plugins

    cp -r dist $out/lib/claude-plugins/
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
