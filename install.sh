#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

"$DRY_RUN" && echo "[dry-run mode]"
echo "Installing dotfiles from $DOTFILES_DIR"

for installer in "$DOTFILES_DIR"/*/install.sh; do
  bash "$installer"
done

echo "Done."
