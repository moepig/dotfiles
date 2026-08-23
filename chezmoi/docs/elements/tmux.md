# tmux

本ドキュメントは、tmux element が管理する設定が定める操作と表示、およびプラグインの取得と読み込みを扱う。

## prefix

prefix は Ctrl+a である。prefix に続けて Ctrl+a を押すと、prefix 自体を前面のプログラムへ送る。prefix に続けて r を押すと `~/.config/tmux/tmux.conf` を読み込み直し、完了をメッセージで表示する。

## キー割り当て

prefix を伴わないキー割り当てを、以下にまとめる。

| キー | 動作 | 設定 |
| --- | --- | --- |
| Alt+w | ウィンドウの新規作成 | `new-window` |
| Alt+d | ウィンドウを閉じる。確認を求める | `confirm-before 'kill-window'` |
| Shift+Left, Shift+Right | 前後のウィンドウへ移動 | `previous-window`, `next-window` |
| Alt+\ | ペインを左右へ分割 | `split-window -h` |
| Alt+- | ペインを上下へ分割 | `split-window -v` |
| Alt+Delete | ペインを閉じる | `kill-pane` |
| Alt+z | ペインのズームの切り替え | `resize-pane -Z` |
| Alt+方向キー | 隣のペインへ移動。端では折り返さない | `select-pane` |
| Alt+[, Alt+] | ペインの幅を 5 桁ずつ増減 | `resize-pane -L 5`, `resize-pane -R 5` |
| Alt+PageUp, Alt+PageDown | ペインの高さを 5 行ずつ増減 | `resize-pane -U 5`, `resize-pane -D 5` |
| Alt+1 〜 Alt+5 | ペイン配置のプリセットの適用 | `select-layout` |
| Alt+a | コピーモードへ入る | `copy-mode` |
| Alt+F12 | クライアントのデタッチ | `detach-client` |
| Alt+F11 | セッションを保存してサーバを終了する。確認を求める | `kill-server` |

分割で開いたペインは分割元のカレントディレクトリを引き継ぐ。ペインの選択、サイズ変更、スクロールはマウスでも行える。

## 表示

status line は上端の 2 行である。1 行目にはウィンドウの一覧を置き、アクティブなウィンドウを反転表示と `<< >>` で示す。右端には主なキー割り当てを並べ、prefix を押している間は左端に `PREFIX` を表示する。2 行目にはペイン番号と実行中のコマンドの一覧を置き、アクティブなペインを反転表示で示す。ズーム中のウィンドウでは `[ZOOM]` を加える。

ウィンドウ名にはカレントディレクトリ名を自動で表示する。

ペインヘッダは上端の枠線に置き、ペイン番号、実行中のコマンド、カレントディレクトリ、および Git リポジトリ名とブランチ名を表示する。Git の情報は `~/.config/tmux/git-pane-info.sh` が出力し、Git リポジトリの外では何も表示しない。枠線と文字の色はアクティブなペインとそれ以外で分ける。非アクティブなペインは背景と文字色を暗くする。

端末の色は `tmux-256color` を用い、`xterm-256color` に対しては truecolor を有効にする。

## 制御列の透過

`allow-passthrough` を有効にし、DCS で包まれた制御列を外側の端末へそのまま渡す。WezTerm のシェル統合が、tmux の内側からユーザ変数を通知するために要する。通知の内容は、[WezTerm のシェル統合](wezterm-shell.md) を参照。

## コピーモードとクリップボード連携

コピーモードのキー操作は vi に倣う。y または Enter でコピーしてコピーモードを抜け、コピーした内容を `~/.config/tmux/copy-to-clipboard.sh` へ渡す。

渡し先の選択は、このスクリプトが実行の時点で行う。選択の結果を、以下にまとめる。

| 実行環境 | 渡し先 |
| --- | --- |
| macOS | `pbcopy` |
| WSL | UTF-16LE へ変換したうえで `clip.exe` |
| それ以外の Linux | `xclip` |

WSL であるかの判定は、`/proc/version` が microsoft を含むかで行う。

> [!NOTE]
> `xclip` は nix 層の tmux feature が導入する。導入するパッケージは、[Nix による構成の管理](../../../nix/docs/configuration.md) を参照。

## プラグイン

読み込むプラグインを、以下にまとめる。

| プラグイン | 内容 |
| --- | --- |
| tmux-sensible | 既定値の調整 |
| tmux-resurrect | セッションの保存と復元 |
| tmux-continuum | tmux-resurrect の定期実行 |

プラグインの取得と読み込みは TPM (tmux plugin manager) が行う。宣言は `~/.config/tmux/tmux.conf` の `@plugin` であり、末尾の `run` が TPM を起動する。tmux-continuum は tmux-resurrect の読み込みを前提とするため、宣言の順序は tmux-sensible、tmux-resurrect、tmux-continuum とする。

TPM 自体は chezmoi の external として `~/.config/tmux/plugins/tpm` へ取得する。TPM が他のプラグインを展開する位置も同じディレクトリであり、展開されたプラグインは chezmoi の管理対象に含まない。

プラグインの導入は、適用の後に実行するスクリプトが TPM の `install_plugins` を呼び出して行う。スクリプトは `tmux.conf` の内容が変わったときのみ実行する。tmux が未導入の場合、および TPM の取得前は何も行わない。

tmux-continuum の保存間隔は 3 分である。復元は、保存結果が `${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last` にある場合に限り有効にする。

## 配置されるファイル

tmux element が配置するファイルを、以下にまとめる。

| パス | 内容 |
| --- | --- |
| `~/.config/tmux/tmux.conf` | tmux の設定 |
| `~/.config/tmux/git-pane-info.sh` | ペインヘッダへ Git リポジトリ名とブランチ名を表示するスクリプト |
| `~/.config/tmux/copy-to-clipboard.sh` | コピーした内容をクリップボードへ渡すスクリプト |
| `~/.config/tmux/plugins/tpm` | TPM。external として取得する |
