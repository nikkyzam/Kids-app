#!/bin/bash
# SessionStart hook for Claude Code on the web.
#
# Flutter is not preinstalled in remote sessions, so this installs a pinned
# Flutter SDK (matching .github/workflows) and fetches package dependencies so
# `flutter analyze` and `flutter test` work in-session. Idempotent and
# non-interactive; safe to run multiple times.
set -euo pipefail

# Only run in Claude Code on the web / remote environments.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_VERSION="3.24.0"
FLUTTER_HOME="${HOME}/flutter"

# Install the Flutter SDK if it isn't already present (git clone is cached
# between sessions once the container state is snapshotted).
if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION}..."
  git clone --depth 1 --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git "${FLUTTER_HOME}"
fi

# Flutter refuses to run from a directory git considers "dubiously owned".
git config --global --add safe.directory "${FLUTTER_HOME}" || true

export PATH="${FLUTTER_HOME}/bin:${PATH}"

# Persist Flutter on PATH for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${FLUTTER_HOME}/bin:\$PATH\"" >> "${CLAUDE_ENV_FILE}"
fi

# Bootstrap the bundled Dart SDK / tooling, then fetch dependencies.
flutter --version
flutter pub get

echo "Flutter environment ready."
