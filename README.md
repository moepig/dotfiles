# dotfiles

本ドキュメントは、[chezmoi](https://www.chezmoi.io/) で管理する dotfiles のリポジトリ構成、セットアップ手順、および運用手順を説明する。

chezmoi は、リポジトリ内のソースディレクトリの内容をホームディレクトリへ複製するツールである。適用先のパスをソース側のファイル名で表現し、OS ごとの差分をテンプレートで吸収する。適用はシンボリックリンクではなく実ファイルの書き込みで行うため、シンボリックリンクを扱いにくい Windows でも同じリポジトリを共有できる。

## 管理対象

ホームディレクトリへ適用される内容を、以下にまとめる。

| ターゲット | 内容 | 適用対象 |
| --- | --- | --- |
| `~/.config/tmux/tmux.conf` | tmux の設定 | Linux, WSL |
| `~/.config/tmux/git-pane-info.sh` | ペインヘッダへ Git リポジトリ名とブランチ名を表示するスクリプト | Linux, WSL |
| `~/.config/nix/nix.conf` | Nix の設定 | Linux, WSL |
| `~/.config/home-manager/flake.nix` | home-manager の flake 定義 | Linux, WSL |
| `~/.config/home-manager/home.nix` | home-manager が導入するパッケージと有効化する設定 | Linux, WSL |
| `~/.config/tmux/plugins/tpm` | TPM (tmux plugin manager) のリポジトリ | Linux, WSL |
| `~/.config/Code/User/settings.json` | VS Code のユーザ設定 | Linux, WSL |
| `%APPDATA%\Code\User\settings.json` | VS Code のユーザ設定 | Windows |
| `%USERPROFILE%\.config\wezterm\wezterm.lua` | WezTerm の設定 | Windows |
| `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` | Windows Terminal の設定のうち、管理対象として指定したキーのみ | Windows |

VS Code のユーザ設定は、OS ごとに配置先が異なるだけで内容は同一である。共有する内容は `.chezmoitemplates/vscode-settings.json` に置き、各ターゲットのテンプレートから参照する。

> [!NOTE]
> `~/.config/tmux/plugins` 配下のうち chezmoi が管理するのは TPM 自身のみである。同じディレクトリへ展開される他のプラグインは TPM が、`~/.config/home-manager/flake.lock` は Nix が生成する。Windows Terminal の `state.json` はウィンドウ位置などのマシン固有の状態であり、管理対象ではない。

> [!IMPORTANT]
> WSL 上で VS Code をリモート接続で使う場合、ユーザ設定を読むのは Windows 側の VS Code である。WSL 上で適用した `~/.config/Code/User/settings.json` は参照されない。Windows 上で chezmoi を適用すること。

## リポジトリ構成

ソースディレクトリはリポジトリ直下ではなく `home/` である。この対応はリポジトリ直下の `.chezmoiroot` が定める。README や CI 設定をソースディレクトリの除外対象として書かずに済ませるためである。

```
.
├── .chezmoiroot                  ソースディレクトリの位置 (home)
├── .gitattributes                作業ツリーの改行コードを LF に固定
├── README.md
└── home/                         ソースディレクトリ
    ├── .chezmoi.toml.tmpl        chezmoi 自身の設定。init 時に生成される
    ├── .chezmoiignore            ターゲットごとの適用可否
    ├── .chezmoiexternal.toml.tmpl  外部リポジトリの取得定義
    ├── .chezmoitemplates/         複数のターゲットで共有する内容
    │   └── vscode-settings.json
    ├── run_onchange_after_install-tmux-plugins.sh.tmpl
    ├── AppData/                   Windows 専用のターゲット
    │   ├── Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/
    │   │   └── modify_settings.json.ps1.tmpl
    │   └── Roaming/Code/User/
    │       └── settings.json.tmpl
    └── private_dot_config/
        ├── Code/User/
        │   └── settings.json.tmpl
        ├── home-manager/
        │   ├── flake.nix.tmpl
        │   └── home.nix
        ├── nix/
        │   └── nix.conf
        ├── tmux/
        │   ├── executable_git-pane-info.sh
        │   └── tmux.conf.tmpl
        └── wezterm/
            └── wezterm.lua
```

ソース側のファイル名に付く接頭辞と接尾辞の意味を、以下にまとめる。

| 記法 | 意味 |
| --- | --- |
| `dot_` 接頭辞 | 適用先のパスでは `.` に置換される。`private_dot_config` は `~/.config` を指す |
| `executable_` 接頭辞 | 適用時に実行権限を付与する。Windows では無視される |
| `private_` 接頭辞 | 適用時に所有者以外の権限を落とす。Windows では無視される |
| `.tmpl` 接尾辞 | テンプレートとして展開してから書き込む |
| `run_onchange_after_` 接頭辞 | ファイル内容が前回と変化したときに限り、適用の完了後に実行する |
| `modify_` 接頭辞 | 適用先の現在の内容を標準入力で受け取り、標準出力を新しい内容とするスクリプトとして扱う |

接頭辞が無い場合、chezmoi は適用先のディレクトリを 0755 とし、既存のディレクトリの権限も変更する。`dot_config` ではなく `private_dot_config` としているのは、`~/.config` の権限を XDG Base Directory の慣習である 0700 に保つためである。

## OS ごとの差分の扱い

差分の吸収は 4 つのファイルで行う。それぞれの役割は次のとおりである。

`.chezmoi.toml.tmpl` は、chezmoi 自身の設定を `chezmoi init` の時点で生成する。ここでカーネルの `osrelease` を判定し、WSL 上で動作しているかを `isWSL` としてテンプレートへ渡す。chezmoi は WSL を `linux` と認識するため、WSL 固有の分岐にはこの値を用いる。Windows では、あわせて `modify_` スクリプトの実行に用いる `[interpreters.ps1]` を設定する。

`.chezmoiignore` は、ターゲットごとの適用可否を定める。tmux、Nix、home-manager は Windows では動作しないため、Windows のときに限り除外する。逆に `AppData` 配下と WezTerm の設定は Windows 以外で除外する。

`.chezmoitemplates` は、複数のターゲットから参照する内容を置く。配置先だけが OS ごとに異なり内容が同一である設定は、実体をここへ置き、各ターゲットのテンプレートを `{{ template "<名前>" . }}` の 1 行にする。

`.chezmoiexternal.toml.tmpl` は、リポジトリに含めずに取得する外部リソースを定める。TPM の取得がこれに当たる。取得は `refreshPeriod` で指定した間隔で更新され、Windows では定義自体が空になる。

tmux のクリップボード連携は、`tmux.conf.tmpl` の中で `isWSL` により分岐する。WSL では `clip.exe`、それ以外の Linux では `xclip` を用いる。

## GUI が書き換えるファイルの扱い

アプリケーション自身が書き換える設定ファイルは、ファイル全体を管理対象にすると GUI からの変更が適用のたびに失われる。この種のファイルは `modify_` 接頭辞を付けたスクリプトで扱い、管理対象として指定したキーのみを上書きする。

Windows Terminal の `settings.json` がこれに当たる。GUI からの設定変更に加え、WSL ディストリビューションなどの動的プロファイルを Windows Terminal 自身が追記するためである。

管理対象のキーは `.chezmoitemplates/windows-terminal-settings.json` に記述する。スクリプトはこれを適用先の現在の内容へ統合する。統合の規則は次のとおりである。

- 双方が辞書であるキーは再帰的に統合する
- それ以外のキーは管理対象の値で上書きする
- 配列は要素単位の統合を行わず、全体を置き換える
- 管理対象に現れないキーは変更しない

スクリプトの実行には PowerShell を用いる。ターゲット名を `settings.json` に保ったまま実行方法を拡張子で決める必要があるため、ソース側のファイル名は `modify_settings.json.ps1.tmpl` とする。chezmoi は `modify_` スクリプトのファイル名から実行方法を表す拡張子を取り除いてターゲット名を決めるためである。

> [!NOTE]
> 適用後の `settings.json` は PowerShell による整形結果となり、Windows Terminal が書き込んだ整形とは異なる。JSON としての内容は変わらない。

## WezTerm の設定

Windows 上の端末として WezTerm を用いる。設定は `~/.config/wezterm/wezterm.lua` に置く。WezTerm は Windows でもこのパスを設定ファイルの探索対象に含むためである。

既定の接続先は `WSL:Ubuntu-24.04` である。起動時と、タブおよびペインの新規作成時のいずれも、WSL 上のシェルが開く。フォントと配色は Windows Terminal のプロファイルと同じ値を指定する。`font_size` と Windows Terminal の `font.size` はともにポイント単位であり、ピクセル数への変換にはディスプレイの DPI を用いるため、同じ値が同じ大きさになる。

> [!NOTE]
> フォントと配色の値は `.chezmoitemplates/windows-terminal-settings.json` と `wezterm.lua` の双方に持つ。参照する形式が JSON と Lua で異なるためである。一方を変える場合は他方も合わせること。

### 接続先の選択

既定の接続先が WSL であるため、Windows 側のシェルは launcher menu から起動する。launcher menu は WezTerm のネイティブ UI であり、タブバーの新規タブボタン (+) の右クリック、または Alt+Shift+w で開く。選んだ項目は新しいタブとして開く。

launcher menu へ並べる項目を、以下にまとめる。

| 項目 | 接続先のドメイン | 起動するプログラム |
| --- | --- | --- |
| WSL: Ubuntu-24.04 | `WSL:Ubuntu-24.04` | ディストリビューションの既定のシェル |
| PowerShell | `local` | `powershell.exe -NoLogo` |
| Command Prompt | `local` | `cmd.exe` |

接続先のドメインを省いた項目は `default_domain` で起動するため、Windows 側のシェルには `local` を明示する。ペインの分割は分割元のペインと同じドメインで行うため、PowerShell のタブを分割すると PowerShell のペインが増える。

### キー割り当て

tmux の window はタブ、pane はペインへ対応する。WezTerm へ設定したキー割り当てを、以下にまとめる。tmux から移したものは対応する設定を併記する。WezTerm の既定のキー割り当ては残し、この表の分のみを上書きする。

| キー | 動作 | 対応する tmux の設定 |
| --- | --- | --- |
| Ctrl+a | leader | `set -g prefix C-a` |
| Ctrl+a Ctrl+a | Ctrl+a を WSL 側へ送る | `bind-key C-a send-prefix` |
| Ctrl+a r | 設定の再読み込み | `bind-key r source-file` |
| Alt+Shift+w | launcher menu を開く | - |
| Alt+w | タブの新規作成 | `new-window` |
| Alt+d | タブを閉じる。確認を求める | `confirm-before 'kill-window'` |
| Shift+Left, Shift+Right | 前後のタブへ移動 | `previous-window`, `next-window` |
| Alt+\ | ペインを左右へ分割 | `split-window -h` |
| Alt+- | ペインを上下へ分割 | `split-window -v` |
| Alt+Delete | ペインを閉じる。確認を求める | `kill-pane` |
| Alt+z | ペインのズームの切り替え | `resize-pane -Z` |
| Alt+方向キー | 隣のペインへ移動。端では折り返さない | `select-pane` |
| Alt+[, Alt+] | ペインの幅を 5 桁ずつ増減 | `resize-pane -L 5`, `resize-pane -R 5` |
| Alt+PageUp, Alt+PageDown | ペインの高さを 5 行ずつ増減 | `resize-pane -U 5`, `resize-pane -D 5` |
| Alt+a | コピーモードへ入る | `copy-mode` |
| コピーモード中の y, Enter | コピーして抜ける | `copy-pipe-and-cancel` |

WezTerm の `copy_mode` キーテーブルは vi のキー操作を既定に持ち、tmux の `mode-keys vi` に対応する。既定でコピーへ割り当てられているのは `y` のみであるため、`Enter` を同じ動作へ差し替える。コピー先は Windows のクリップボードであり、tmux が WSL 上で行っていた `clip.exe` への受け渡しは要さない。

### 表示

tmux の status line に対応する表示は、WezTerm のタブバーで行う。タブバーは上端に置き、タブが 1 つのときも隠さない。タブ名にはカレントディレクトリ名を表示し、leader を押している間はタブバーの右端に `LEADER` を表示する。非アクティブなペインは減光する。

ウィンドウの背景は不透明度 0.9 の半透明とし、背後を Acrylic でぼかす。Acrylic は背後の内容をぼかす効果であり、`window_background_opacity` が 1.0 未満のときに有効となる。

> [!NOTE]
> Acrylic は Mica および Tabbed よりも多くのシステムリソースを消費する。

> [!IMPORTANT]
> タブ名のカレントディレクトリは、シェルが OSC 7 で通知した値を用いる。WSL のペインでは Windows 側からプロセスのカレントディレクトリを辿れないためである。通知が無い場合、タブ名はペインのタイトルとなる。

> [!TIP]
> OSC 7 の通知は WSL 側のシェルで設定する。bash であれば `~/.bashrc` へ次を加える。
>
> ```bash
> PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}'printf "\033]7;file://%s%s\033\\" "$HOSTNAME" "$PWD"'
> ```

### 移していない設定

tmux の設定のうち、WezTerm へ移していないものと、その理由を以下にまとめる。

| tmux の設定 | 内容 | 理由 |
| --- | --- | --- |
| `select-layout` (Alt+1 〜 Alt+5) | ペイン配置のプリセット | WezTerm に対応する機能が無い |
| `detach-client` (Alt+F12), `kill-server` (Alt+F11) | クライアントのデタッチとサーバの終了 | WSL のドメインは multiplexer サーバを介さないため、対象が無い |
| tmux-resurrect, tmux-continuum | セッションの保存と復元 | WezTerm に対応する機能が無い |
| `pane-border-format` | ペインヘッダへの Git リポジトリ名とブランチ名の表示 | 端末画面への描画となるため |
| `status-format[1]` | ペイン番号と実行中のコマンドの一覧 | 端末画面への描画となるため |
| `status-format[0]` の右端 | キー割り当ての一覧 | 端末画面への描画となるため。WezTerm のコマンドパレット (Ctrl+Shift+P) が代わる |

## セットアップ

chezmoi 本体は Nix ではなく OS のパッケージマネージャで導入する。Nix と home-manager の設定ファイルを chezmoi が配置するため、chezmoi の適用をそれらの導入より先に行う必要があるためである。

リポジトリの実体は `~/src/dotfiles` に置き、chezmoi の既定のソースディレクトリである `~/.local/share/chezmoi` からシンボリックリンクで参照させる。

### Linux および WSL

Debian 系ディストリビューションを前提とする。

1. chezmoi を導入する。

    ```bash
    sudo snap install chezmoi --classic
    ```

2. リポジトリを取得し、ソースディレクトリとして参照させる。

    ```bash
    git clone https://github.com/moepig/dotfiles ~/src/dotfiles
    mkdir -p ~/.local/share
    ln -s ~/src/dotfiles ~/.local/share/chezmoi
    ```

3. 設定を生成して適用する。

    ```bash
    chezmoi init --apply
    ```

4. Nix を導入する。完了後にシェルを再起動する。

    ```bash
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
    ```

5. home-manager を適用する。

    ```bash
    nix run home-manager/master -- switch --flake ~/.config/home-manager
    ```

    以後の更新は `home-manager switch --flake ~/.config/home-manager` で行う。

> [!IMPORTANT]
> WSL2 で snap を使うには systemd が有効である必要がある。`/etc/wsl.conf` に `[boot]` セクションの `systemd=true` を記述し、`wsl --shutdown` で再起動すること。

### Windows

1. chezmoi を導入する。

    ```powershell
    winget install twpayne.chezmoi
    ```

2. リポジトリを取得して適用する。

    ```powershell
    chezmoi init --apply moepig/dotfiles
    ```

    ターゲットは `%USERPROFILE%`、ソースディレクトリは `%USERPROFILE%\.local\share\chezmoi` である。

## 既存のシンボリックリンクからの移行

移行前の構成では、`install.sh` が各設定ファイルへのシンボリックリンクをホームディレクトリへ作成していた。chezmoi は実ファイルを書き込むため、リンクが残った状態で適用してはいけない。

`~/src/dotfiles` に移行後のリポジトリがある状態からは、次の手順で移行する。

```bash
sudo snap install chezmoi --classic

rm -f ~/.config/tmux/tmux.conf ~/.config/tmux/git-pane-info.sh \
      ~/.config/nix/nix.conf \
      ~/.config/home-manager/flake.nix ~/.config/home-manager/home.nix

# TPM の配置先が ~/.config/tmux/plugins/tpm へ変わったため、旧配置を削除する
rm -rf ~/.tmux/plugins/tpm

mkdir -p ~/.local/share
ln -s ~/src/dotfiles ~/.local/share/chezmoi

chezmoi init --apply
```

> [!NOTE]
> `install.sh` が退避した `*.bak` が同じディレクトリに残っている。内容を確認したうえで削除してよい。

## 運用手順

日常的に用いるコマンドを、以下にまとめる。

| コマンド | 用途 |
| --- | --- |
| `chezmoi edit <ターゲット>` | 対応するソース側のファイルを編集する |
| `chezmoi diff` | 未適用の差分を表示する |
| `chezmoi apply` | ソースの内容をホームディレクトリへ反映する |
| `chezmoi add <ターゲット>` | 既存のファイルを管理対象へ取り込む |
| `chezmoi cd` | ソースディレクトリでサブシェルを開く |
| `chezmoi update` | リモートリポジトリを取得して適用する |

外部リソースの取得は `refreshPeriod` の期間内はキャッシュされる。即時に取得し直す場合は `chezmoi --refresh-externals apply` を用いる。

テンプレートの展開結果は `chezmoi execute-template < <ファイル>` で確認できる。

## 設定の追加

ソース側のパスは、ホームディレクトリからの相対パスに `dot_` などの接頭辞を適用したものである。`chezmoi add` を用いれば、この変換は自動で行われる。

Windows 専用のターゲットを追加する場合の指針は次のとおりである。

- `%USERPROFILE%` 直下から見た相対パスをそのまま用いる。先頭がドットでないパスに接頭辞は付かない。PowerShell のプロファイルであれば `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` となる
- Windows 以外では適用されないよう、`.chezmoiignore` の `{{ if ne .chezmoi.os "windows" }}` 側へ除外を書く
- 改行コードは `.gitattributes` により LF に固定される。chezmoi はソースの内容をそのまま書き込むため、適用後のファイルも LF になる
