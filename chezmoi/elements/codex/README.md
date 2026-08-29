# codex

本ドキュメントは、codex element が管理する Codex の設定を扱う。

`~/.codex/config.toml` の既存内容へ、管理対象のキーのみを統合する。ファイル全体は管理しない。

## 管理対象のキー

適用によって値が定まるキーを、以下にまとめる。

| キー | 値 | 内容 |
| --- | --- | --- |
| `approval_policy` | `"on-request"` | コマンドの承認が必要かを Codex が判断する |
| `sandbox_mode` | `"workspace-write"` | カレントワークスペースと追加された書き込み可能ディレクトリへの書き込みを許可する |
| `tui.animations` | `false` | TUI のアニメーションを無効にする |

## 統合の規則

`modify_` スクリプトは、適用先の現在の内容を標準入力で受け取って次の規則で統合する。

- `approval_policy` と `sandbox_mode` が無い場合は、最初のテーブルより前へ加える
- `approval_policy` または `sandbox_mode` がある場合は、管理対象の値にする
- `[tui]` が無い場合は、ファイルの末尾へテーブルと管理対象のキーを加える
- `[tui]` があり、`animations` が無い場合は、次のテーブルより前に管理対象のキーを加える
- `animations` がある場合は、値を `false` にする
- 管理対象以外の行は内容と順序を保持する

> [!IMPORTANT]
> 加えた設定は、element を profile から外しても `~/.codex/config.toml` に残る。`modify_` スクリプトは適用の対象から外れた時点で実行されなくなるためである。削除は手作業で行うこと。
