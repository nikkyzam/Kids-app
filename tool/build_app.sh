#!/usr/bin/env bash
# Build one app of the family. Keeps the Android --flavor and the Dart
# APP_FLAVOR define in lockstep so they cannot drift apart.
#
#   tool/build_app.sh <app-id> <appbundle|apk|ios|run> [extra flutter args...]
#
# Supabase credentials come from the environment (SUPABASE_URL,
# SUPABASE_ANON_KEY) so each app can point at its own backend. BUILD_NAME and
# BUILD_NUMBER, when set (the release workflow sets them from the tag),
# override pubspec.yaml's shared version so each app is versioned on its own.
set -euo pipefail

app="${1:?usage: build_app.sh <app-id> <appbundle|apk|ios|run> [args...]}"
cmd="${2:?usage: build_app.sh <app-id> <appbundle|apk|ios|run> [args...]}"
shift 2

defines=(--dart-define=APP_FLAVOR="$app")
[ -n "${SUPABASE_URL:-}" ] && defines+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
[ -n "${SUPABASE_ANON_KEY:-}" ] && defines+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")

# Expanded with the ${a[@]+...} guard below: macOS's bash 3.2 treats an
# empty array as unset under `set -u` and would abort a plain local build.
versions=()
[ -n "${BUILD_NAME:-}" ] && versions+=(--build-name="$BUILD_NAME")
[ -n "${BUILD_NUMBER:-}" ] && versions+=(--build-number="$BUILD_NUMBER")

case "$cmd" in
  run) exec flutter run --flavor "$app" "${defines[@]}" "$@" ;;
  appbundle | apk) exec flutter build "$cmd" --release --flavor "$app" "${defines[@]}" ${versions[@]+"${versions[@]}"} "$@" ;;
  # Mode and signing are the caller's: e.g. `ios --release --no-codesign`.
  ios) exec flutter build ios --flavor "$app" "${defines[@]}" ${versions[@]+"${versions[@]}"} "$@" ;;
  *) echo "unknown command: $cmd" >&2; exit 2 ;;
esac
