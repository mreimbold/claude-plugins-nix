# claude-plugins-nix

Nix flake for [claude-plugins](https://github.com/Kamalnrf/claude-plugins) - providing both standalone derivations and a home-manager module for managing Claude Code plugins and agent skills across multiple AI coding clients.

## Features

- **Two CLI tools**: `claude-plugins` for plugin management and `skills-installer` for agent skills
- **Declarative configuration**: Define plugins and skills in your home-manager config
- **Multi-client support**: Install skills for claude-code, cursor, vscode, and 6 other AI clients
- **Automatic installation**: Plugins and skills install during home-manager activation
- **Flexible options**: Simple mode for most users, advanced per-client mode for power users

## Quick Start

### Standalone Installation

```bash
# Install both tools
nix profile install github:yourusername/claude-plugins-nix

# Or install individually
nix profile install github:yourusername/claude-plugins-nix#claude-plugins
nix profile install github:yourusername/claude-plugins-nix#skills-installer
```

### Flake Usage

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-plugins-nix.url = "github:yourusername/claude-plugins-nix";
  };

  outputs = { nixpkgs, home-manager, claude-plugins-nix, ... }: {
    homeConfigurations.youruser = home-manager.lib.homeManagerConfiguration {
      modules = [
        claude-plugins-nix.homeManagerModules.default
        ./home.nix
      ];
    };
  };
}
```

## Home-Manager Configuration

### Basic Example

```nix
{
  programs.claude-tools = {
    # Enable plugin manager
    claude-plugins = {
      enable = true;
      plugins = [
        "@anthropics/claude-code-plugins/pr-review-toolkit"
      ];
    };

    # Enable skills installer
    skills-installer = {
      enable = true;
      globalSkills = [
        "@anthropics/skills/frontend-design"
        "@anthropics/skills/pdf"
      ];
    };
  };
}
```

### Multi-Client Example

Install skills for multiple AI coding clients:

```nix
{
  programs.claude-tools.skills-installer = {
    enable = true;

    # Install for both Claude Code and Cursor
    clients = [ "claude-code" "cursor" ];

    globalSkills = [
      "@anthropics/skills/frontend-design"
      "@anthropics/skills/pdf"
    ];
  };
}
```

### Advanced Per-Client Configuration

Different skills for different clients:

```nix
{
  programs.claude-tools.skills-installer = {
    enable = true;

    # Advanced mode: per-client skill lists
    skillsByClient = {
      claude-code = {
        global = [
          "@anthropics/skills/frontend-design"
          "@anthropics/skills/pdf"
        ];
        local = [ ];
      };

      cursor = {
        global = [
          "@anthropics/skills/xlsx"
        ];
        local = [
          "@project/skills/custom-analyzer"
        ];
      };

      vscode = {
        global = [
          "@vscode/skills/custom"
        ];
        local = [ ];
      };
    };
  };
}
```

## Configuration Options

### `programs.claude-tools.claude-plugins`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | boolean | `false` | Enable claude-plugins CLI tool |
| `package` | package | `pkgs.claude-plugins` | Package to use |
| `plugins` | list of strings | `[]` | Plugins to install automatically |

**Plugin format**: `@owner/marketplace/plugin-name`

### `programs.claude-tools.skills-installer`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | boolean | `false` | Enable skills-installer CLI tool |
| `package` | package | `pkgs.skills-installer` | Package to use |
| `clients` | list of enums | `["claude-code"]` | AI clients to install skills for |
| `globalSkills` | list of strings | `[]` | Skills to install globally for all clients |
| `localSkills` | list of strings | `[]` | Skills to install locally for all clients |
| `skillsByClient` | attrset | `{}` | Advanced: per-client skill configuration |

**Skill format**: `@owner/repo/skill-name`

**Supported clients**: `claude-code`, `codex`, `cursor`, `github`, `letta`, `vscode`, `amp`, `goose`, `opencode`

## CLI Usage

Once installed, you can use the tools directly:

### claude-plugins

```bash
# Install a plugin
claude-plugins install @anthropics/claude-code-plugins/pr-review-toolkit

# List installed plugins
claude-plugins list

# Enable/disable plugins
claude-plugins enable pr-review-toolkit
claude-plugins disable pr-review-toolkit
```

Plugins are installed to `~/.claude/plugins/marketplaces/`

### skills-installer

```bash
# Install a skill globally for claude-code (default)
skills-installer install @anthropics/skills/frontend-design

# Install for a specific client
skills-installer install --client cursor @anthropics/skills/xlsx

# Install locally to current project
skills-installer install --local @project/skills/custom-skill

# List installed skills
skills-installer list
skills-installer list --client cursor

# Search for skills
skills-installer search "testing"
skills-installer search "database" --client vscode
```

Global skills install to `~/.claude/skills/` (or client-specific directory)
Local skills install to `./.claude/skills/`

## Development

### Build Locally

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-plugins-nix.git
cd claude-plugins-nix

# Build individual packages
nix build .#claude-plugins
nix build .#skills-installer
nix build .#default

# Test the binaries
./result/bin/claude-plugins --help
./result/bin/skills-installer --help

# Enter development shell
nix develop
```

### Update Upstream

```bash
# Update to latest claude-plugins version
nix flake lock --update-input claude-plugins-src

# Or update all inputs
nix flake update
```

## How It Works

### Build Process

1. Fetches source from upstream [claude-plugins repository](https://github.com/Kamalnrf/claude-plugins)
2. Uses Bun to install dependencies (`bun install --frozen-lockfile`)
3. Compiles TypeScript to JavaScript (`bun run build`)
4. Creates wrapper scripts that execute via Bun runtime
5. Copies built dist and node_modules to Nix store

### Home-Manager Integration

When you enable the home-manager module:

1. **Package Installation**: Adds CLI tools to `home.packages`
2. **Activation Scripts**: Runs during `home-manager switch`
3. **Idempotency**: Checks if plugin/skill already installed before installing
4. **Error Handling**: Uses graceful fallbacks to prevent activation failures

The activation scripts run after `writeBoundary` to ensure all files are in place.

## Upstream

This package builds the CLI tools from the official [claude-plugins repository](https://github.com/Kamalnrf/claude-plugins).

- **claude-plugins** (v0.2.0): Plugin manager for Claude Code
- **skills-installer** (v0.1.3): Agent skills installer for multiple AI clients

## License

MIT - Same as upstream claude-plugins

## Automated Dependency Updates

This repository uses GitHub Actions to automatically manage dependency updates:

- **Schedule**: Daily at 8:00 AM UTC
- **Inputs tracked**: `nixpkgs` (NixOS/nixpkgs/nixos-unstable) and `claude-plugins-src` (Kamalnrf/claude-plugins)
- **PR behavior**: All updates grouped into a single pull request
- **CI validation**: Builds all packages and tests executables before creating PR
- **Labels**: PRs are tagged with `dependencies` and `automated`

### How It Works

1. The workflow runs `nix flake update` to update all inputs
2. Builds `claude-plugins`, `skills-installer`, and `default` packages
3. Tests that executables run correctly
4. Creates a PR only if changes were detected and builds succeed
5. CI runs on the PR to validate on both Linux and macOS

### Manual Updates

You can still manually update inputs when needed:

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
nix flake lock --update-input claude-plugins-src

# Test builds
nix build .#claude-plugins
nix build .#skills-installer
```

### Manual Workflow Trigger

You can manually trigger the update workflow:

1. Go to the "Actions" tab in GitHub
2. Select "Update Flake Inputs" workflow
3. Click "Run workflow"

### Adjusting Update Frequency

Edit the cron schedule in `.github/workflows/update-flake-inputs.yml`:

- Daily (current): `'0 8 * * *'`
- Weekly: `'0 8 * * 1'` (Mondays)
- Bi-weekly: `'0 8 1,15 * *'` (1st and 15th)

## Contributing

Contributions welcome! Please open issues or pull requests on GitHub.

### Maintenance Notes

When upstream releases new versions with breaking changes:

1. The automated PR may fail CI builds
2. Review the flake.lock diff to identify what changed
3. Update `version` in derivation files (`packages/*.nix`) if needed
4. Test home-manager integration
5. Update README if new features/options added
