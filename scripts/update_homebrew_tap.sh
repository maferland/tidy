#!/bin/bash
set -euo pipefail

VERSION="${1:?Usage: update_homebrew_tap.sh VERSION DMG_PATH}"
DMG_PATH="${2:?Usage: update_homebrew_tap.sh VERSION DMG_PATH}"

if [ ! -f "$DMG_PATH" ]; then
    echo "Error: DMG not found at $DMG_PATH"
    exit 1
fi

SHA=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
CASK_VERSION="${VERSION#v}"

echo "Updating homebrew tap: version=$CASK_VERSION sha256=$SHA"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

gh repo clone maferland/homebrew-tap "$WORK_DIR" -- --depth 1

if [ -n "${GH_TOKEN:-}" ]; then
    git -C "$WORK_DIR" remote set-url origin "https://x-access-token:${GH_TOKEN}@github.com/maferland/homebrew-tap.git"
fi

CASK_FILE="$WORK_DIR/Casks/tidy.rb"

cat > "$CASK_FILE" << CASK
cask "tidy" do
  version "$CASK_VERSION"
  sha256 "$SHA"

  url "https://github.com/maferland/tidy/releases/download/v#{version}/Tidy-v#{version}-macos.dmg"
  name "Tidy"
  desc "Automatically clean up messy clipboard text"
  homepage "https://github.com/maferland/tidy"

  depends_on macos: ">= :sonoma"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "Tidy.app"

  zap trash: "~/Library/Preferences/com.maferland.tidy.plist"
end
CASK

cd "$WORK_DIR"
git add Casks/tidy.rb
git commit -m "Update tidy to $VERSION"
git push

echo "Homebrew tap updated"
