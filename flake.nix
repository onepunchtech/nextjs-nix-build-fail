{
  description = "my project description";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs?rev=2117c50988e796dc76bab4b5fc9dab84dbb91098";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        web = pkgs.mkYarnPackage rec {
          name = "ui";

          version = "0.0.1";
          packageJSON = ./package.json;
          yarnLock = ./yarn.lock;
          src = pkgs.nix-gitignore.gitignoreSource [] ./.;

          buildPhase = ''
            export HOME=$(mktemp -d)
            yarn --offline build
          '';


          installPhase = ''
            mkdir -p $out
            mv package.json $out
            mv next.config.js $out
            mv next-env.d.ts $out
            mv tsconfig.json $out
            cp -a node_modules $out/node_modules
            mv .next $out
          '';

          distPhase = "true";

          configurePhase = ''
            ln -s $node_modules node_modules
          '';

          nativeBuildInputs = [ pkgs.makeWrapper ];
        };

        myDevTools = [
          pkgs.nodejs
          pkgs.yarn
          pkgs.skopeo
        ];

        builds = pkgs.callPackage ./nix/builds.nix {inherit pkgs self;};

        ui-image = pkgs.dockerTools.buildImage {
          name = "ui";
          tag = "latest";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [pkgs.bashInteractive pkgs.coreutils web pkgs.yarn];
            pathsToLink = [ "/" ];
          };

          config = {
            Cmd = [ "yarn" "start"];
            Env = [
              "NODE_ENV=production"
              "NEXT_SHARP_PATH=/node_modules/sharp"
            ];
            ExposedPorts = {
              "3000/tcp" = {};
            };
          };
        };

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = myDevTools;
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath myDevTools;
        };

        defaultPackage = web;

        packages = {
          web = web;
          ui-image = ui-image;
        };
      });
}
