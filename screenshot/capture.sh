#!/usr/bin/env bash
# Render the README screenshots without touching the running Zed.
#
# Starts a second, throwaway Zed in the background (ZED_STATELESS skips Zed's
# one-instance-per-user check; --user-data-dir gives it its own config), opens
# the sample project, and captures only that process's window with
# `screencapture -l`. The window stays behind whatever is focused.
#
#   screenshot/capture.sh [Zed.app]

set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
app=${1:-/Applications/Zed.app}
out=$repo/screenshots
data=$(mktemp -d "${TMPDIR:-/tmp}/zed-shot.XXXXXX")/data
pid=

cleanup() {
  if [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
  fi
  rm -rf "$(dirname "$data")"
}
trap cleanup EXIT

write_settings() {
  cat >"$data/config/settings.json" <<EOF
{
  "theme": "$1",
  "buffer_font_size": 13,
  "ui_font_size": 15,
  "disable_ai": true,
  "auto_update": false,
  "telemetry": { "diagnostics": false, "metrics": false },
  "session": { "trust_all_worktrees": true },
  "enable_language_server": false,
  "auto_install_extensions": {},
  "git": { "inline_blame": { "enabled": false } },
  "project_panel": { "dock": "left" },
  "minimap": { "show": "always" },
  "show_edit_predictions": false
}
EOF
}

# One fresh instance per theme: switching themes live leaves some cached
# colors (the matching-bracket fill) from the previous theme.
shoot() {
  local theme=$1 file=$2 window=
  rm -rf "$data" && mkdir -p "$data/config/themes"
  cp "$repo/themes/tokyonight.json" "$data/config/themes/"
  write_settings "$theme"

  open -g -n --env ZED_STATELESS=1 -a "$app" --args \
    --user-data-dir "$data" "$here/sample" "$here/sample/src/palette.rs:33:9"

  # Our instance is the zed process whose arguments name our data dir.
  pid=
  for _ in $(seq 50); do
    pid=$(pgrep -f -- "--user-data-dir $data" | head -1 || true)
    [[ -n $pid ]] && break
    sleep 0.2
  done
  [[ -n $pid ]] || { echo "zed did not start" >&2; exit 1; }

  for _ in $(seq 50); do
    window=$(swift "$here/window-id.swift" "$pid")
    [[ -n $window ]] && break
    sleep 0.2
  done
  [[ -n $window ]] || { echo "no zed window" >&2; exit 1; }

  sleep "${ZED_SHOT_SETTLE:-3}" # first paint and syntax parse
  screencapture -x -o -l "$window" "$out/$file"
  sips --resampleWidth 1600 "$out/$file" >/dev/null
  kill "$pid"
  while kill -0 "$pid" 2>/dev/null; do sleep 0.2; done
  echo "wrote screenshots/$file"
}

mkdir -p "$out"
shoot "TokyoNight Night" night.png
shoot "TokyoNight Storm" storm.png
shoot "TokyoNight Moon" moon.png
shoot "TokyoNight Day" day.png
