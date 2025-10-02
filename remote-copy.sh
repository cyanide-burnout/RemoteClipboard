#!/usr/bin/env bash
set -euo pipefail

if [[ ${1-} == '-e' ]]
then
  exec tee >("$0" "${@:2}")
fi

if [ -S "/tmp/clipboard.${USER}.sock" ]
then
  socat -u - "UNIX-CONNECT:/tmp/clipboard.${USER}.sock"
  exit 0
fi

if [[ -n "${TMUX:-}" || -n "${SSH_TTY:-}" ]]
then
  TTY="${TMUX:+$(tmux display-message -p '#{client_tty}')}"
  TTY="${TTY:-${SSH_TTY:-}}"
  { printf '\e]52;c;'; base64 | tr -d '\r\n'; printf '\a'; } > "$TTY"
  exit 0
fi
