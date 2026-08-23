# wezterm-shell

本ドキュメントは、wezterm-shell element が管理する WezTerm のシェル統合スクリプトの取得、読み込み、およびスクリプトが端末へ通知する内容を扱う。

## スクリプトの取得

スクリプトは chezmoi の external として取得する。宣言は `elements/wezterm-shell/home/.chezmoiexternal.toml` に置き、取得元の URL は次のとおりである。

```
https://raw.githubusercontent.com/wezterm/wezterm/76b606ec597a3c0263fa60321548637451c0a547/assets/shell-integration/wezterm.sh
```

URL は WezTerm のコミットを指す。取得した内容は `~/.cache/chezmoi` に保持し、`refreshPeriod` の 168 時間を過ぎた適用で取得し直す。上流の更新を取り込むには、URL のコミットを差し替える。

> [!IMPORTANT]
> URL へブランチを指定してはいけない。ブランチが指す内容は上流の更新に伴って変わり、`refreshPeriod` を過ぎた適用のたびに配置される内容が変わるためである。

> [!NOTE]
> external の取得には GitHub への接続を要する。接続できない場合、chezmoi は取得済みの内容を用いる。

## 配置と読み込み

スクリプトは `~/.config/wezterm/shell-integration.sh` へ配置する。読み込みの記述は `~/.config/bash/rc.d/90-wezterm.bashrc` へ置く。番号を 90 とするのは、スクリプトが `PROMPT_COMMAND` を書き換えるため、他の初期化より後に読み込む必要があるためである。読み込みの経路は、[bash の設定](../bash/README.md) を参照。

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
> ユーザ変数の通知は、tmux の内側では DCS で包んだうえで送出する。tmux がこれを外側の端末へ渡すよう、tmux の設定は `allow-passthrough` を有効にしている。設定の内容は、[tmux の設定](../tmux/README.md) を参照。

## 配置されるファイル

wezterm-shell element が配置するファイルを、以下にまとめる。

| パス | 内容 |
| --- | --- |
| `~/.config/wezterm/shell-integration.sh` | WezTerm のシェル統合スクリプト。external として取得する |
| `~/.config/bash/rc.d/90-wezterm.bashrc` | シェル統合スクリプトの読み込み |
