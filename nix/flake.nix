{
  description = "Home Manager configuration for home-dev-wsl2";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      # 構成を構築する system。構成は WSL2 のマシンを表すため、1 つに定める
      system = "x86_64-linux";

      # 適用先のユーザ名。flake の評価は既定で環境変数を参照しないため、値の取得には --impure を要する
      username =
        let
          env = builtins.getEnv "USER";
        in
        if env != "" then env else throw "USER を取得できない。--impure を伴って実行すること";

      # 適用の単位となる構成
      configurations = {
        home-dev-wsl2 = ./configurations/home-dev-wsl2.nix;
      };

      mkConfiguration =
        module:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};

          # feature から flake の入力を参照するために渡す
          extraSpecialArgs = { inherit inputs; };

          modules = [
            module
            { home.username = username; }
          ];
        };
    in
    {
      homeConfigurations = lib.mapAttrs (_name: mkConfiguration) configurations;
    };
}
