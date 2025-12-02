cask "mbconverter" do
  version "0.0.2"
  sha256 "4ff3b5d0191e9a982d29e25c74b94a56ad7fd2d58d81eed2cf3b60991a614565"

  url "https://github.com/jdfwarrior/menubar-converter/releases/download/v#{version}/mbconverter-#{version}.zip"
  name "mbconverter"
  desc "Menubar app that converts MKV files to MP4 using HandBrakeCLI"
  homepage "https://github.com/jdfwarrior/menubar-converter"

  depends_on macos: ">= :catalina"

  app "MBConverter.app"

  zap trash: [
    "~/Library/Application Support/MBConverter",
  ]
end
