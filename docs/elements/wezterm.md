# WezTerm のシェル統合

本ドキュメントは、WezTerm のシェル統合スクリプトの取得、配置、読み込み、およびスクリプトが端末へ通知する内容を説明する。適用対象は Linux のみである。

## スクリプトの取得

スクリプトは flake の入力 `wezterm-shell-integration` として取得する。入力が指す URL は次のとおりである。

```
https://raw.githubusercontent.com/wezterm/wezterm/76b606ec597a3c0263fa60321548637451c0a547/assets/shell-integration/wezterm.sh
```

URL は WezTerm のコミットを指す。取得した内容は `flake.lock` が narHash として固定する。上流の更新を取り込むには、`flake.nix` の URL のコミットを差し替えたうえで、次のコマンドを実行する。

```bash
nix flake update wezterm-shell-integration
```

> [!IMPORTANT]
> URL へブランチを指定してはいけない。ブランチが指す内容は上流の更新に伴って変わり、`flake.lock` が固定した narHash と一致しなくなった時点で構成の評価が中断するためである。

## 配置と読み込み

スクリプトは `~/.config/wezterm/shell-integration.sh` へ配置する。読み込みの記述は `~/.config/bash/nix.bashrc` の末尾へ加える。スクリプトが PROMPT_COMMAND を書き換えるため、他の初期化より後に置く。読み込みの経路は、[bash の設定](bash.md) を参照。

スクリプトは、bash と zsh 以外のシェル、非対話のシェル、および `TERM` が `linux` または `dumb` である端末では何も行わずに終了する。

## 端末へ通知する内容

スクリプトがプロンプトの表示ごとに送出する制御列と、その内容を、以下にまとめる。

| 制御列 | 内容 | 無効にする環境変数 |
| --- | --- | --- |
| OSC 7 | カレントディレクトリ | `WEZTERM_SHELL_SKIP_CWD` |
| OSC 133 | プロンプト、入力、出力の範囲を示すセマンティックゾーン | `WEZTERM_SHELL_SKIP_SEMANTIC_ZONES` |
| OSC 1337 SetUserVar | ユーザ名、ホスト名、実行中のコマンド名、tmux の内側かどうか | `WEZTERM_SHELL_SKIP_USER_VARS` |

いずれの環境変数も、値を `1` として設定すると対応する通知を行わない。`WEZTERM_SHELL_SKIP_ALL` を `1` とすると、スクリプトは何も行わずに終了する。

> [!NOTE]
> ユーザ変数の通知は、tmux の内側では DCS で包んだうえで送出する。tmux がこれを外側の端末へ渡すよう、tmux の設定は `allow-passthrough` を有効にしている。設定の内容は、[tmux の設定](tmux.md) を参照。
