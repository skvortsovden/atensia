#!/usr/bin/env bash
# build-local-apk.sh
# Builds a dev APK locally and uploads it to the latest-dev GitHub Release
# so it appears on https://skvortsovden.github.io/atensia/builds/index.html
#
# Prerequisites: flutter, gh (GitHub CLI, authenticated)
#
# Usage:
#   ./scripts/build-local-apk.sh            # auto build number (timestamp)
#   ./scripts/build-local-apk.sh 42         # explicit build number

set -euo pipefail

REPO="skvortsovden/atensia"
RELEASE_TAG="latest-dev"

# ── 1. Resolve version from pubspec.yaml ──────────────────────────────────────
PUBSPEC="$(dirname "$0")/../pubspec.yaml"
VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: //' | cut -d'+' -f1)
if [[ -z "$VERSION" ]]; then
  echo "❌  Could not read version from pubspec.yaml" >&2
  exit 1
fi

# ── 2. Build number: argument or YYYYMMDDHHMMSS ───────────────────────────────
BUILD_NUMBER="${1:-$(date +%Y%m%d%H%M%S)}"
APK_NAME="atensia-${VERSION}-dev-${BUILD_NUMBER}.apk"
ALIAS_NAME="atensia-dev.apk"

echo "▶  Version   : ${VERSION}"
echo "▶  Build#    : ${BUILD_NUMBER}"
echo "▶  APK name  : ${APK_NAME}"
echo ""

# ── 3. Check prerequisites ────────────────────────────────────────────────────
for cmd in flutter gh; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌  '$cmd' not found. Install it and try again." >&2
    exit 1
  fi
done

# ── 4. Update pubspec build number ───────────────────────────────────────────
PUBSPEC_ABS="$(cd "$(dirname "$0")/.." && pwd)/pubspec.yaml"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' "s/^version: .*/version: ${VERSION}+${BUILD_NUMBER}/" "$PUBSPEC_ABS"
else
  sed -i "s/^version: .*/version: ${VERSION}+${BUILD_NUMBER}/" "$PUBSPEC_ABS"
fi

# Restore pubspec on exit so local checkout stays clean
trap 'git -C "$(dirname "$PUBSPEC_ABS")" checkout -- pubspec.yaml 2>/dev/null || true' EXIT

# ── 5. Build APK ──────────────────────────────────────────────────────────────
cd "$(dirname "$0")/.."
echo "▶  Running flutter build apk …"
flutter build apk \
  --release \
  --build-name="${VERSION}-dev" \
  --build-number="${BUILD_NUMBER}"

SRC="build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$SRC" ]]; then
  echo "❌  APK not found at $SRC" >&2
  exit 1
fi

cp "$SRC" "$APK_NAME"
cp "$APK_NAME" "$ALIAS_NAME"
echo "✅  Built: $APK_NAME"
echo ""

# ── 6. Ensure latest-dev release exists ──────────────────────────────────────
if ! gh release view "$RELEASE_TAG" --repo "$REPO" &>/dev/null; then
  echo "▶  Creating release $RELEASE_TAG …"
  gh release create "$RELEASE_TAG" \
    --repo "$REPO" \
    --title "Atensia latest-dev" \
    --notes "Dev builds — automatically updated." \
    --prerelease
fi

# ── 7. Upload versioned APK (always add) ─────────────────────────────────────
echo "▶  Uploading $APK_NAME …"
gh release upload "$RELEASE_TAG" "$APK_NAME" \
  --repo "$REPO" \
  --clobber

# ── 8. Upload fixed-name alias (for the direct download link on Pages) ───────
echo "▶  Uploading alias $ALIAS_NAME …"
gh release upload "$RELEASE_TAG" "$ALIAS_NAME" \
  --repo "$REPO" \
  --clobber

# ── 9. Cleanup temp files ─────────────────────────────────────────────────────
rm -f "$APK_NAME" "$ALIAS_NAME"

echo ""
echo "✅  Done! Visit https://skvortsovden.github.io/atensia/builds/index.html"
echo "    (may take ~30 s for the page to refresh from the Releases API)"
