# tmux の設定

本ドキュメントは、tmux の設定が定める操作と表示、およびプラグインの読み込みを説明する。適用対象は Linux と macOS である。

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
> `xclip` は tmux の feature が Linux でのみ導入する。導入するパッケージは、[Nix による構成の管理](nix.md) を参照。

## プラグイン

読み込むプラグインを、以下にまとめる。

| プラグイン | 内容 |
| --- | --- |
| tmux-sensible | 既定値の調整 |
| tmux-resurrect | セッションの保存と復元 |
| tmux-continuum | tmux-resurrect の定期実行 |

プラグインは nixpkgs の `tmuxPlugins` から取得する。読み込みの記述は Nix store 上のパスを伴うため、`~/.config/tmux/plugins.conf` として書き出し、`~/.config/tmux/tmux.conf` の末尾から読み込む。tmux-continuum は tmux-resurrect の読み込みを前提とするため、読み込みの順序は tmux-sensible、tmux-resurrect、tmux-continuum とする。

Alt+F11 が実行する保存スクリプトのパスも tmux-resurrect の配置に依存する。このキー割り当ては `plugins.conf` へ書き出す。

tmux-continuum の保存間隔は 3 分である。復元は、保存結果が `${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last` にある場合に限り有効にする。
