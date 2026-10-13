#!/usr/bin/env bash
# Build one app of the family. Keeps the Android --flavor and the Dart
# APP_FLAVOR define in lockstep so they cannot drift apart.
#
#   tool/build_app.sh <app-id> <appbundle|apk|run> [extra flutter args...]
#
# Supabase credentials come from the environment (SUPABASE_URL,
# SUPABASE_ANON_KEY) so each app can point at its own backend.
set -euo pipefail

app="${1:?usage: build_app.sh <app-id> <appbundle|apk|run> [args...]}"
cmd="${2:?usage: build_app.sh <app-id> <appbundle|apk|run> [args...]}"
shift 2

defines=(--dart-define=APP_FLAVOR="$app")
[ -n "${SUPABASE_URL:-}" ] && defines+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
[ -n "${SUPABASE_ANON_KEY:-}" ] && defines+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")

case "$cmd" in
  run) exec flutter run --flavor "$app" "${defines[@]}" "$@" ;;
  appbundle | apk) exec flutter build "$cmd" --release --flavor "$app" "${defines[@]}" "$@" ;;
  *) echo "unknown command: $cmd" >&2; exit 2 ;;
esac
