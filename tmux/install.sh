#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-false}"

run() {
  if "$DRY_RUN"; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

link() {
  local src="$1"
  local dest="$2"

  run mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "  backup: $dest -> $dest.bak"
    run mv "$dest" "$dest.bak"
  fi

  run ln -sfn "$src" "$dest"
  echo "  linked: $dest -> $src"
}

echo "[tmux] Installing config files..."

while IFS= read -r -d '' src; do
  rel="${src#"$SCRIPT_DIR/"}"
  link "$src" "$HOME/$rel"
done < <(find "$SCRIPT_DIR/.config" -type f -print0)

echo "[tmux] Installing TPM..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
  echo "  already exists: $TPM_DIR"
elif "$DRY_RUN"; then
  echo "  [dry-run] git clone https://github.com/tmux-plugins/tpm $TPM_DIR"
else
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

echo "[tmux] Done."
