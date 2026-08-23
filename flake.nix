{
  description = "Home Manager configurations for home and work";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WezTerm のシェル統合スクリプト。flake ではないため、単一のファイルとして取得する。
    # URL はコミットを指す。ブランチを指すと、上流の更新のたびに flake.lock との narHash の不一致で評価が中断するためである
    wezterm-shell-integration = {
      url = "file+https://raw.githubusercontent.com/wezterm/wezterm/76b606ec597a3c0263fa60321548637451c0a547/assets/shell-integration/wezterm.sh";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      # 構成を生成する system
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # system を伴わない名前が指す system
      defaultSystem = "x86_64-linux";

      # 適用先のユーザ名。flake の評価は既定で環境変数を参照しないため、値の取得には --impure を要する
      username =
        let
          env = builtins.getEnv "USER";
        in
        if env != "" then env else throw "USER を取得できない。--impure を伴って実行すること";

      # 適用の単位となる構成
      configurations = {
        home = ./configurations/home.nix;
        work = ./configurations/work.nix;
      };

      mkConfiguration =
        system: module:
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
      # <名前> は defaultSystem 向け、<名前>-<system> は指定した system 向けである
      homeConfigurations =
        lib.mapAttrs (_name: mkConfiguration defaultSystem) configurations
        // lib.listToAttrs (
          lib.concatMap (
            name:
            map (
              system: lib.nameValuePair "${name}-${system}" (mkConfiguration system configurations.${name})
            ) systems
          ) (lib.attrNames configurations)
        );
    };
}
