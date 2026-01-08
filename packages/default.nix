{ lib
, symlinkJoin
, makeWrapper
, claude-plugins
, skills-installer
}:

symlinkJoin {
  name = "claude-tools";
  paths = [ claude-plugins skills-installer ];

  buildInputs = [ makeWrapper ];

  meta = with lib; {
    description = "Combined package with claude-plugins and skills-installer";
    homepage = "https://github.com/Kamalnrf/claude-plugins";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
