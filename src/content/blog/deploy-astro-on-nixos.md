---
title: "Deploying an Astro project on NixOS"
description: "NixOS does things differently, how hard is it to configure an Astro Project?"
pubDate: "May 05 2024"
# heroImage: "/blog-placeholder-3.jpg"
---

[Nix](https://nixos.org) is an incredible project and has completely change the way I think about configuring linux and macOS environments. Recently, I moved my personal server from Ubuntu to NixOS to match my desktop environment. ([dotfiles here!](https://github.com/zackartz/nixos-dots)). In doing so, I realized I needed to move this blog over, too. I could simply deploy a docker container like I did before, but I think it would be interesting and informative to try and build a NixOS module around it. Hopefully you find it useful :)

## The `flake.nix` file.

Nix has a experimental feature called [flakes](https://nixos.wiki/wiki/Flakes), if you've been in the NixOS space long enough you've undoubtably heard of them. Flakes are a new way of writing your package configuration, you expose two objects, `inputs` and `outputs`. Your `inputs` would be things your application depends on, for example, `nixpkgs` (the package repository of Nix). Inputs can be a variety of different things, but typically are git repos. A `flake.lock` file is generated automatically so any consumers of your flake get the exact revisions of each input to guarantee reproducability. The `outputs` section of your flake can contain many things, from `devShells` to entire `nixosConfigurations`, but we are interested in `packages` and `nixosModules` today.

A example for a starter flake for a Astro project may look like this:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
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
    devShells = eachSystem (pkgs: {
      default = pkgs.mkShell {
        buildInputs = [
          pkgs.nodejs

          pkgs.nodePackages.pnpm

          pkgs.nodePackages.typescript
          pkgs.nodePackages.typescript-language-server
          pkgs.nodePackages."@tailwindcss/language-server"
          pkgs.nodePackages."@astrojs/language-server"
        ];
      };
    });
  };
}
```

You can see for my inputs I am taking in `nixpkgs` and `nix-systems`, which I am using to generate a devShell for every system architechture supported by NixOS. The `devShells` all import the following nix packages, `nodejs`, `pnpm`, `typescript`, `typescript-language-server`, `tailwindcss-language-server`, `astrojs-lanaguage-server`. Lets add add a package!

I use [pnpm](https://pnpm.io) as my package manager of choice, and as such we have to add the `pnpm2nix` flake to our inputs, which we can do with the following line.

```nix
 pnpm2nix.url = "github:nzbr/pnpm2nix-nzbr";
```

Now, lets add the package spec:

```nix
{
  outputs = {
    systems,
    nixpkgs,
    self,
    ...
  } @ inputs: let
    eachSystem = f:
      nixpkgs.lib.genAttrs (import systems) (
        system:
          f nixpkgs.legacyPackages.${system}
      );
  in {
    # add packages :)
    packages = eachSystem (pkgs: {
      default = inputs.pnpm2nix.packages.${pkgs.system}.mkPnpmPackage {
        name = "zm-blog";
        src = ./.;
        packageJSON = ./package.json;
        pnpmLock = ./pnpm-lock.yaml;
      };
    });

    # ...
  };
}
```

Now, when we run `nix build`, everything works as expected, great! But how can we see the outputs of our build? If we run the following command:

```bash
󰘧 | nix eval --raw .#packages.x86_64-linux.default
/nix/store/ik5nmb60qrgib5knp4b538axwdxykc8z-zm-blog
```

Awesome, if we ls this path, we get exactly what we are expecting from the build output.

```bash
󰘧 | ls /nix/store/ik5nmb60qrgib5knp4b538axwdxykc8z-zm-blog                                                                     nix-shell-env
 _astro   fonts                    blog-placeholder-2.jpg   blog-placeholder-5.jpg      󰗀 rss.xml
 about    index.html               blog-placeholder-3.jpg   blog-placeholder-about.jpg  󰗀 sitemap-0.xml
 blog     blog-placeholder-1.jpg   blog-placeholder-4.jpg  󰕙 favicon.svg                 󰗀 sitemap-index.xml
```

At this point, we could add this repo as a input to the flake configuring our server, add a new `virtualHost` for the domain we want this to run on, point the root at this package and call it a day, but I want to take it one step further. I want to write a NixOS module to make the configuration server side even easier.

I added the following code to the outputs section of my `flake.nix`.

```nix
{
 # previous outputs

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
         forceSSL = cfg.ssl;
         enableACME = cfg.ssl;
         root = "${packages.${pkgs.system}.default}";
       };
     };
   };
}
```

Woah, that's a lot of code, let's break it down.

Because Nix (the language) is mostly used for configuration, defining variables anywhere could be confusing, so you have to do it in a special scope, that being the `let .. in` syntax. In this example, we are setting the variable `cfg` to be equal to `config.zmio.blog`, for convenience. Notice also the `with lib;`, this allows us to call the values on `lib` as a top-level var, ie, `lib.mkOption` would become `mkOption`.

The `options.zmio.blog` object contains the options, their types and their defaults, and the `config` section is the code that gets executed.

Enough code, lets deploy!

## Deploying on the server

After adding the repo of my blog project to my server's flake like this:

```nix
{
   inputs = {
     # all our previous definitions

     blog.url = "github:zackartz/zmio";
   };

   # ...

   nixosConfigurations.pluto = nixpkgs_stable.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        # previous modules
        inputs.blog.nixosModule
      ];
   };

   # other configs
}
```

We can add the following to our server's main nixosModule:

```nix
   zmio.blog.enable = true;
```

And that should be it, after a rebuild it should be live!

## Conclusion

NixOS allows for a truly unique way of deploying apps, and if you thought this was interesting, be sure to check out Nix! There's tons of other cool stuff to check out!
