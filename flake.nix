{
  description = "archsetup-ansible dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # ansible (full: bundles community.* collections used by this repo)
            ansible
            # linting / static checks (also what a CI would run)
            ansible-lint
            yamllint
            # runtime for helper scripts (update_ollama_jinja.py)
            python3
            # task runner
            just
          ];
          shellHook = ''echo "dev shell ready — run \`just\`"'';
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
