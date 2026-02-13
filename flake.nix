{
  description = "An mpv cheatsheet plug-in in Lua";

  inputs = {
    futils = {
      type = "github";
      owner = "numtide";
      repo = "flake-utils";
      ref = "main";
    };

    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };

    git-hooks = {
      type = "github";
      owner = "cachix";
      repo = "git-hooks.nix";
      ref = "master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, futils, nixpkgs, git-hooks }:
    {
      overlays = {
        default = final: prev: {
          mpvScripts = final.lib.makeScope prev.mpvScripts.newScope (_: {
            mpv-cheatsheet-ng = with final; pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
              pname = "mpv-cheatsheet-ng";
              version = "0.1.0";

              src = self;

              noBuild = true;

              installPhase = ''
                runHook preInstall

                install -D cheatsheet.lua $out/share/mpv/scripts/${finalAttrs.passthru.scriptName}

                runHook postInstall
              '';

              passthru.scriptName = "cheatsheet.lua";

              meta = {
                description = "mpv script for looking up keyboard shortcuts";
                homepage = "https://github.com/ambroisie/mpv-cheatsheet-ng";
                license = lib.licenses.mit;
                maintainers = with lib.maintainers; [ ambroisie ];
              };
            });
          });
        };
      };
    } // futils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
          ];
        };

        pre-commit = git-hooks.lib.${system}.run {
          src = self;

          hooks = {
            nixpkgs-fmt = {
              enable = true;
            };

            stylua = {
              enable = true;
            };
          };
        };
      in
      {
        checks = {
          inherit (self.packages.${system}) mpv-cheatsheet-ng;

          inherit pre-commit;
        };

        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [
              self.packages.${system}.mpv-cheatsheet-ng
            ];

            packages = with pkgs; [
              self.checks.${system}.pre-commit.enabledPackages
            ];

            inherit (pre-commit) shellHook;
          };
        };

        packages = futils.lib.flattenTree {
          default = pkgs.mpvScripts.mpv-cheatsheet-ng;
          inherit (pkgs.mpvScripts) mpv-cheatsheet-ng;
        };
      });
}
