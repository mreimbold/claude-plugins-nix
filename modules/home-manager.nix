{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-tools;
in
{
  options.programs.claude-tools = {
    claude-plugins = {
      enable = mkEnableOption "the claude-plugins CLI tool";

      package = mkOption {
        type = types.package;
        default = pkgs.claude-plugins or (
          throw "claude-plugins not available in pkgs. Use flake overlay or add the package to your flake inputs."
        );
        defaultText = literalExpression "pkgs.claude-plugins";
        description = "The claude-plugins package to use.";
      };

      plugins = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "@anthropics/claude-code-plugins/pr-review-toolkit" ];
        description = ''
          List of plugins to install automatically.
          Format: @owner/marketplace/plugin-name
          Plugins are installed to ~/.claude/plugins/marketplaces/
        '';
      };
    };

    skills-installer = {
      enable = mkEnableOption "the skills-installer CLI tool";

      package = mkOption {
        type = types.package;
        default = pkgs.skills-installer or (
          throw "skills-installer not available in pkgs. Use flake overlay or add the package to your flake inputs."
        );
        defaultText = literalExpression "pkgs.skills-installer";
        description = "The skills-installer package to use.";
      };

      clients = mkOption {
        type = types.listOf (types.enum [
          "claude-code"
          "codex"
          "cursor"
          "github"
          "letta"
          "vscode"
          "amp"
          "goose"
          "opencode"
        ]);
        default = [ "claude-code" ];
        example = [ "claude-code" "cursor" "vscode" ];
        description = ''
          List of AI coding clients to install skills for.
          Skills from globalSkills and localSkills will be installed
          for each client in this list using the --client flag.
        '';
      };

      globalSkills = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "@anthropics/skills/frontend-design" "@anthropics/skills/pdf" ];
        description = ''
          List of skills to install globally for all clients in the clients list.
          Format: @owner/repo/skill-name
          Installed for each client to their respective global directories.
        '';
      };

      localSkills = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "@project/skills/custom-skill" ];
        description = ''
          List of skills to install locally for all clients in the clients list.
          Format: @owner/repo/skill-name
          Installed for each client to ./.claude/skills/
        '';
      };

      skillsByClient = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            global = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Global skills for this specific client";
            };
            local = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Local skills for this specific client";
            };
          };
        });
        default = { };
        example = {
          cursor = {
            global = [ "@anthropics/skills/xlsx" ];
            local = [ ];
          };
          vscode = {
            global = [ "@vscode/skills/custom" ];
            local = [ ];
          };
        };
        description = ''
          Advanced escape hatch: specify skills per client explicitly.
          Useful when different clients need different skill sets.
          Takes precedence over clients/globalSkills/localSkills options.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.claude-plugins.enable {
      home.packages = [ cfg.claude-plugins.package ];

      # Install declared plugins
      home.activation.installClaudePlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${lib.optionalString (cfg.claude-plugins.plugins != [ ]) ''
          $DRY_RUN_CMD ${cfg.claude-plugins.package}/bin/claude-plugins list > /dev/null 2>&1 || true
          ${lib.concatMapStringsSep "\n" (plugin: ''
            if ! ${cfg.claude-plugins.package}/bin/claude-plugins list 2>/dev/null | grep -q "${plugin}"; then
              $VERBOSE_ECHO "Installing plugin: ${plugin}"
              $DRY_RUN_CMD ${cfg.claude-plugins.package}/bin/claude-plugins install "${plugin}" || true
            fi
          '') cfg.claude-plugins.plugins}
        ''}
      '';
    })

    (mkIf cfg.skills-installer.enable {
      home.packages = [ cfg.skills-installer.package ];

      # Install declared global and local skills
      home.activation.installSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${let
          # Determine if using simple mode or advanced skillsByClient
          useSimpleMode = cfg.skills-installer.skillsByClient == { };

          # Generate installation commands for simple mode
          simpleCommands = lib.optionalString useSimpleMode ''
            ${lib.concatMapStringsSep "\n" (client: ''
              ${lib.concatMapStringsSep "\n" (skill: ''
                if ! ${cfg.skills-installer.package}/bin/skills-installer list --client ${client} 2>/dev/null | grep -q "${skill}"; then
                  $VERBOSE_ECHO "Installing global skill for ${client}: ${skill}"
                  $DRY_RUN_CMD ${cfg.skills-installer.package}/bin/skills-installer install --client ${client} "${skill}" || true
                fi
              '') cfg.skills-installer.globalSkills}
              ${lib.concatMapStringsSep "\n" (skill: ''
                if ! ${cfg.skills-installer.package}/bin/skills-installer list --client ${client} 2>/dev/null | grep -q "${skill}"; then
                  $VERBOSE_ECHO "Installing local skill for ${client}: ${skill}"
                  $DRY_RUN_CMD ${cfg.skills-installer.package}/bin/skills-installer install --client ${client} --local "${skill}" || true
                fi
              '') cfg.skills-installer.localSkills}
            '') cfg.skills-installer.clients}
          '';

          # Generate installation commands for advanced per-client mode
          advancedCommands = lib.optionalString (!useSimpleMode) ''
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (client: skills: ''
              ${lib.concatMapStringsSep "\n" (skill: ''
                if ! ${cfg.skills-installer.package}/bin/skills-installer list --client ${client} 2>/dev/null | grep -q "${skill}"; then
                  $VERBOSE_ECHO "Installing global skill for ${client}: ${skill}"
                  $DRY_RUN_CMD ${cfg.skills-installer.package}/bin/skills-installer install --client ${client} "${skill}" || true
                fi
              '') skills.global}
              ${lib.concatMapStringsSep "\n" (skill: ''
                if ! ${cfg.skills-installer.package}/bin/skills-installer list --client ${client} 2>/dev/null | grep -q "${skill}"; then
                  $VERBOSE_ECHO "Installing local skill for ${client}: ${skill}"
                  $DRY_RUN_CMD ${cfg.skills-installer.package}/bin/skills-installer install --client ${client} --local "${skill}" || true
                fi
              '') skills.local}
            '') cfg.skills-installer.skillsByClient)}
          '';
        in simpleCommands + advancedCommands}
      '';
    })
  ];
}
