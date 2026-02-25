cask "tidy" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/maferland/tidy/releases/download/v#{version}/Tidy-v#{version}-macos.dmg"
  name "Tidy"
  desc "Automatically clean up messy clipboard text"
  homepage "https://github.com/maferland/tidy"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Tidy.app"

  zap trash: [
    "~/Library/Preferences/com.maferland.tidy.plist",
  ]
end
