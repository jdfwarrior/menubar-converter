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
cd MBConverter
swift build -c release
swift run MBConverter
```

To make this a real macOS app bundle, open Xcode and create a new macOS App target, add these sources, set `Info.plist` and code signing as needed.

Notes & limitations

- The package uses `NSStatusBar` directly; to convert this into a distributable .app, use Xcode and sign appropriately.
- HandBrakeCLI path is `/usr/local/bin/HandBrakeCLI` by default; adjust if installed elsewhere.
- The code attempts simple parsing of filenames to extract a 4-digit year when the base filename is dot-delimited.
