#!/bin/bash
path="${1:-$PWD}"
cd "$path" 2>/dev/null || exit 1
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
repo=$(basename "$toplevel")
branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
printf '[%s:%s]' "$repo" "$branch"
