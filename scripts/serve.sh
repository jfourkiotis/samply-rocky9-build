#!/usr/bin/env bash
# Serve the bundled Firefox Profiler frontend over plain HTTP so samply
# can hand profiles to it without going to profiler.firefox.com.
#
# Usage: ./serve.sh [port]
#   Default port is 4242. Binds to 127.0.0.1 only.
set -euo pipefail

PORT="${1:-4242}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$DIR/profiler-dist"

if [[ ! -f "$DIST/index.html" ]]; then
  echo "error: $DIST/index.html not found" >&2
  echo "Are you running this from inside the unpacked bundle?" >&2
  exit 1
fi

cd "$DIST"
echo "Serving Firefox Profiler at http://127.0.0.1:$PORT"
echo "Point samply at it with:"
echo "  PROFILER_URL=http://127.0.0.1:$PORT $DIR/bin/samply load profile.json.gz"
exec python3 -m http.server "$PORT" --bind 127.0.0.1
