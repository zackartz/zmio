{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    pnpm2nix.url = "github:nzbr/pnpm2nix-nzbr";
  };

  outputs = {
    systems,
    nixpkgs,
    ...
  } @ inputs: let
    eachSystem = f:
      nixpkgs.lib.genAttrs (import systems) (
        system:
          f nixpkgs.legacyPackages.${system}
      );
  in {
    packages = eachSystem (pkgs: {
      default = inputs.pnpm2nix.packages.${pkgs.system}.mkPnpmPackage {
        name = "zm-blog";
        src = ./.;
        packageJSON = ./package.json;
        pnpmLock = ./pnpm-lock.yaml;
      };
    });

    nixosModule = {
      config,
      lib,
      pkgs,
      ...
    }:
      with lib; let
        cfg = config.zmio.blog;
      in {
        options.zmio.blog = {
          enable = mkEnableOption "Enables the Blog Site";

          domain = mkOption rec {
            type = type.str;
            default = "zackmyers.io";
            example = default;
            description = "The domain name for the website";
          };

          ssl = mkOption rec {
            type = type.bool;
            default = true;
            example = default;
            description = "Whether to enable SSL on the domain or not";
          };
        };

        config = mkIf cfg.enable {
          services.nginx.virtualHosts.${cfg.domain} = {
            forceSSL = ${cfg.ssl};
            enableACME = ${cfg.ssl};
            root = "${packages.${pkgs.system}.default}";
          };
        };
      };

    devShells = eachSystem (pkgs: {
      default = pkgs.mkShell {
        buildInputs = [
          pkgs.nodejs
          # You can set the major version of Node.js to a specific one instead
          # of the default version
          # pkgs.nodejs-19_x

          # You can choose pnpm, yarn, or none (npm).
          pkgs.nodePackages.pnpm
          # pkgs.yarn

          pkgs.nodePackages.typescript
          pkgs.nodePackages.typescript-language-server
          pkgs.nodePackages."@tailwindcss/language-server"
          pkgs.nodePackages."@astrojs/language-server"
        ];
      };
    });
  };
}
