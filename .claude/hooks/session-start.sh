#!/bin/bash
# SessionStart hook for Claude Code on the web.
#
# Installs the Flutter SDK version CI uses and fetches packages, so
# `flutter analyze`, `flutter test` and builds in-session behave like CI.
# Idempotent and non-interactive; safe to run multiple times.
#
# The version is read from .github/workflows/ci.yml (FLUTTER_VERSION), so the
# session and CI cannot drift apart. It is installed into its own directory,
# ~/flutter-<version>, and put first on PATH: a cloud environment's setup
# script may already have put a different Flutter in ~/flutter (it did: 3.24,
# which made 18 tests fail and rewrote pubspec.lock every session).
set -euo pipefail

# Only run in Claude Code on the web / remote environments.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"

FLUTTER_VERSION="$(sed -n 's/^ *FLUTTER_VERSION: *\([0-9.]*\).*/\1/p' .github/workflows/ci.yml | head -1)"
if [ -z "${FLUTTER_VERSION}" ]; then
  echo "Could not read FLUTTER_VERSION from .github/workflows/ci.yml" >&2
  exit 1
fi
FLUTTER_HOME="${HOME}/flutter-${FLUTTER_VERSION}"

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION}..."
  base="https://storage.googleapis.com/flutter_infra_release/releases"
  # The release index gives the archive path and its SHA-256.
  read -r archive sha256 < <(curl -fsSL "${base}/releases_linux.json" | python3 -c '
import json, sys
v = sys.argv[1]
r = next(x for x in json.load(sys.stdin)["releases"] if x["version"] == v and x["channel"] == "stable")
print(r["archive"], r["sha256"])' "${FLUTTER_VERSION}")
  tmp="$(mktemp -d)"
  curl -fsSL "${base}/${archive}" -o "${tmp}/flutter.tar.xz"
  echo "${sha256}  ${tmp}/flutter.tar.xz" | sha256sum -c --quiet
  mkdir -p "${FLUTTER_HOME}"
  tar -xJf "${tmp}/flutter.tar.xz" -C "${FLUTTER_HOME}" --strip-components=1
  rm -rf "${tmp}"
fi

# Flutter refuses to run from a directory git considers "dubiously owned".
git config --global --add safe.directory "${FLUTTER_HOME}" || true

export PATH="${FLUTTER_HOME}/bin:${PATH}"

# Persist this Flutter first on PATH for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${FLUTTER_HOME}/bin:\$PATH\"" >> "${CLAUDE_ENV_FILE}"
fi

# Bootstrap the bundled Dart SDK / tooling, then fetch dependencies.
flutter --version
flutter pub get

echo "Flutter environment ready."
