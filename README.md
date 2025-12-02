# MBConverter

MBConverter is a small macOS menubar app that scans a configured folder for `.mkv` files and converts them to MP4 using HandBrakeCLI with the "Apple 1080p60 Surround" preset.

Features:

- Runs in the menu bar only.
- Reads config from `~/Library/Application Support/MBConverter/config.json`.
- Scans recursively on configured interval (seconds).
- Converts one file at a time using `HandBrakeCLI`.
- Keeps only English audio, preserves subtitles and chapters, optimizes for streaming, passes through metadata.
- Rotating logs in `~/Library/Application Support/MBConverter/logs`.
- Sends macOS notifications on completion.

Config (example):

```
{
  "path": "~/Movies/ToConvert",
  "interval": 120
}

Add an `exclude` array to ignore folders (paths may be absolute or use `~`):

```

{
"path": "~/Movies/ToConvert",
"interval": 120,
"exclude": [
"/Volumes/Movies/#recycled",
"~/Movies/Trash"
]
}

```

```

Build & Run

1. Install HandBrakeCLI (`brew install handbrake` or download official CLI).
2. From this folder run:

```bash
cd src
swift build -c release
swift run MBConverter
```

To make this a real macOS app bundle, open Xcode and create a new macOS App target, add these sources, set `Info.plist` and code signing as needed.

Notes & limitations

- The package uses `NSStatusBar` directly; to convert this into a distributable .app, use Xcode and sign appropriately.
- HandBrakeCLI path is `/usr/local/bin/HandBrakeCLI` by default; adjust if installed elsewhere.
- The code attempts simple parsing of filenames to extract a 4-digit year when the base filename is dot-delimited.

## Install via Homebrew (personal tap)

You can provide the app as a Homebrew Cask from this repository (personal tap). This repo already contains `Casks/mbconverter.rb` and a GitHub Actions workflow that builds and creates releases when you push tags.

To install from your tap (public or private repo):

```bash
# add the tap (public):
brew tap jdfwarrior/menubar-converter https://github.com/jdfwarrior/menubar-converter

# install the cask
brew install --cask mbconverter

# or in one step without tapping explicitly:
brew install --cask jdfwarrior/menubar-converter/mbconverter
```

Notes:

- The GitHub Actions workflow in this repo triggers on tag pushes (tags like `v0.1.0`) and produces a GitHub Release containing the built `.zip` of `MBConverter.app`. The workflow also updates `Casks/mbconverter.rb` with the new `version` and `sha256` for the release.
- If the repository is private, only users with access can `brew tap` it; the cask will not be discoverable via `brew search` unless it is added to the official `homebrew/cask` repo.
