{
  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          lib,
          system,
          pkgs,
          ...
        }:
        {
          devShells.default =
            let
              inherit (pkgs) mkShell nodejs pnpm;
            in
            mkShell {
              packages = [
                nodejs
                pnpm
              ];
            };

          packages = rec {
            nixpkgs-tracker = pkgs.stdenv.mkDerivation rec {
              pname = "nixpkgs-tracker";
              version =
                let
                  lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
                in
                builtins.substring 0 8 lastModifiedDate;

              src = ./.;

              pnpmDeps = pkgs.pnpm.fetchDeps {
                inherit pname version src;
                hash = "sha256-bu8Xgt/pTlOjgrP3owIsmdrslStU4egXuRm0RyKdohQ=";
              };

              nativeBuildInputs = with pkgs; [
                nodejs
                pnpm.configHook
              ];

              buildPhase = "pnpm build";

              installPhase = ''
                runHook preInstall

                mkdir $out
                mv dist $out

                runHook postInstall
              '';
            };

            default = nixpkgs-tracker;
          };
        };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

}
