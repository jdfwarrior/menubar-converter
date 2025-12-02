cask "mbconverter" do
  version "0.0.3"
  sha256 "b5110fe7b39abea5fdad3463125667605dd93a43a002d092ced7b73ce1f3765a"

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
