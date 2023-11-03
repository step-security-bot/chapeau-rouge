{
  description = "Chapeau rouge, an overlay of Red Hat tools for Nix";

  outputs = inputs@{ self, nixpkgs, flake-parts, pre-commit-hooks, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        # Inidividual overlays.
        # self: super: must be named final: prev: for `nix flake check` to be happy
        overlays = {
          default = final: prev: import ./overlays final prev;
          openshift = final: prev: import ./overlays/openshift.nix final prev;
          # package = final: prev: import ./overlays/package.nix final prev;
        };
      };
      systems = [ "aarch64-linux" "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ];
      perSystem = { system, config, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowAliases = false;
            overlays = [ self.overlays.default ];
          };
          inherit (pkgs) lib;
          overlayAttrs = builtins.attrNames (import ./overlays pkgs pkgs);
        in
        {
          packages =
            let
              drvAttrs = builtins.filter (n: lib.isDerivation pkgs.${n}) overlayAttrs;
            in
            lib.listToAttrs (map (n: lib.nameValuePair n pkgs.${n}) drvAttrs);

          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                nixpkgs-fmt.enable = true;
                # nix-linter.enable = true;
                # statix.enable = true;
              };
            };
          };
          devShells.default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = with pkgs; [
              pre-commit
            ];
          };
        };
    };

  # outputs = { self, nixpkgs, flake-parts, pre-commit-hooks }: {
  #   # Inidividual overlays.
  #   # self: super: must be named final: prev: for `nix flake check` to be happy
  #   overlays = {
  #     default = final: prev: import ./overlays final prev;
  #     openshift = final: prev: import ./overlays/openshift.nix final prev;
  #     # package = final: prev: import ./overlays/package.nix final prev;
  #   };
  # 
  # } // flake-utils.lib.eachSystem [ "aarch64-linux" "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ]
  #   (system:
  #     let
  #       pkgs = import nixpkgs {
  #         inherit system;
  #         config.allowAliases = false;
  #         overlays = [ self.overlays.default ];
  #       };
  #       inherit (pkgs) lib;
  #       overlayAttrs = builtins.attrNames (import ./. pkgs pkgs);
  #     in
  #     {
  #       packages =
  #         let
  #           drvAttrs = builtins.filter (n: lib.isDerivation pkgs.${n}) overlayAttrs;
  #         in
  #         lib.listToAttrs (map (n: lib.nameValuePair n pkgs.${n}) drvAttrs);
  # 
  #       checks = {
  #         pre-commit-check = pre-commit-hooks.lib.${system}.run {
  #           src = ./.;
  #           hooks = {
  #             nixpkgs-fmt.enable = true;
  #             # nix-linter.enable = true;
  #             # statix.enable = true;
  #           };
  #         };
  #       };
  #       devShells.default = pkgs.mkShell {
  #         inherit (self.checks.${system}.pre-commit-check) shellHook;
  #         buildInputs = with pkgs; [
  #           pre-commit
  #         ];
  #       };
  #     }
  #   );

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
}

