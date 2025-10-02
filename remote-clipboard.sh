#!/bin/bash
set -euo pipefail

if [ $# -eq 0 ]
then
  echo "Usage: $0 [ssh options] [user@]host"
  exit 2
fi

NAME="$(printf '%s\n' "$@" | grep -oE '[^[:space:]]+@' | tail -n1 | tr -d '@' || printf '%s' "$USER")"
FOLDER="$(mktemp -d "${TMPDIR:-/tmp}/clipboard.XXXXXXXX")"
COPIER=""

LOCAL="$FOLDER/clipboard.sock"
REMOTE="/tmp/clipboard.${NAME}.sock"

[ -z "$COPIER" ] && [ "$(uname -s)" == "Darwin" ]   && COPIER="$(command -v pbcopy)"
[ -z "$COPIER" ] && [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null && COPIER="$(command -v wl-copy) --type text/plain"
[ -z "$COPIER" ] && [[ -n "${DISPLAY:-}" ]]         && command -v xclip   >/dev/null && COPIER="$(command -v xclip)   -selection clipboard -in -quiet"
[ -z "$COPIER" ] && [[ -n "${DISPLAY:-}" ]]         && command -v xsel    >/dev/null && COPIER="$(command -v xsel)    --clipboard --input"
[ -z "$COPIER" ] && { [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE 'microsoft|WSL' /proc/version >/dev/null; } && command -v clip.exe >/dev/null && COPIER="$(command -v clip.exe)"
[ -z "$COPIER" ]            && { echo "No clipboard backend" >&2; exit 1; }
command -v socat >/dev/null || { echo "socat is required"    >&2; exit 1; }

rm -f "$LOCAL"
socat -u UNIX-LISTEN:"$LOCAL",fork,unlink-early,umask=0077 SYSTEM:"$COPIER" &
PROCESS=$!
trap 'kill "$PROCESS" 2>/dev/null || true; wait "$PROCESS" 2>/dev/null || true; rm -rf "$FOLDER" || true' EXIT INT TERM

ssh -o ExitOnForwardFailure=yes -o StreamLocalBindUnlink=yes -t -R "$REMOTE":"$LOCAL" "$@" \
  "REMOTE='$REMOTE' bash -lc 'trap \"rm -f $REMOTE\" INT TERM EXIT; read -r -p \"*** Press Ctrl-C or Enter to exit ***\" _'"
