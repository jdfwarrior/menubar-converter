cask "mbconverter" do
  version "0.0.0"
  sha256 "PLACEHOLDER"

  url "https://github.com/jdfwarrior/menubar-converter/releases/download/v#{version}/MBConverter-#{version}.zip"
  name "MBConverter"
  desc "Menubar app that converts MKV files to MP4 using HandBrakeCLI"
  homepage "https://github.com/jdfwarrior/menubar-converter"

  depends_on macos: ">= :catalina"

  app "MBConverter.app"

  zap trash: [
    "~/Library/Application Support/MBConverter",
  ]
end
