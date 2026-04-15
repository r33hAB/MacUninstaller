# MacUninstaller

A native macOS app for uninstalling applications and analyzing disk storage. Built with Swift and SwiftUI.

## Features

### App Uninstaller
- Scan all installed apps (including Steam, Homebrew, and non-standard locations)
- See app sizes with associated file breakdowns (caches, preferences, support files)
- Uninstall apps with one click — moves app bundle and all associated files to Trash
- Batch uninstall multiple apps at once
- Touch ID / password authentication for admin-protected apps (cached for session)
- Finder right-click integration ("Uninstall with MacUninstaller")
- Risky mode for removing system apps (requires explicit unlock)
- Storage insights: reclaimable space, unused apps, largest apps

### File Analyzer
- Apple-style storage visualization with segmented disk usage bar
- Smart categorization: Documents, Downloads, Developer, Music, Photos, Caches
- Browse files by Folder, Type, or Date with expandable groups
- Smart cleanup suggestions:
  - Old installers (DMGs/PKGs for already-installed apps)
  - Apps sitting in Downloads (move to /Applications)
  - Stale downloads (6+ months old)
  - Duplicate and near-duplicate files
  - Extracted archives (ZIP next to extracted folder)
  - Developer artifacts (node_modules, DerivedData, Pods, venv)
  - Old screenshots, cache bloat, large files
- Per-file actions: delete, reveal in Finder, move to Applications
- Batch folder selection and deletion

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Setup

```bash
git clone https://github.com/r33hab/MacUninstaller.git
cd MacUninstaller
xcodegen generate
open MacUninstaller.xcodeproj
```

Then press `⌘R` in Xcode to build and run.

## Project Structure

```
MacUninstaller/
├── MacUninstaller/          # Main app target
│   ├── Models/              # Data models (AppInfo, ScannedFile, etc.)
│   ├── Services/            # Business logic (scanners, suggestion engine)
│   ├── ViewModels/          # SwiftUI view models
│   ├── Views/               # SwiftUI views
│   └── Theme/               # Colors, styles, animations
├── HelperTool/              # Privileged helper for admin operations
├── FinderExtension/         # Finder Sync extension (right-click menu)
├── Shared/                  # Code shared between targets
└── MacUninstallerTests/     # Unit tests
```

## Architecture

- **3 Xcode targets**: Main app, privileged helper tool (XPC), Finder Sync extension
- **AuthorizationServices** with C bridge for Touch ID support and session-cached admin rights
- **Parallel file scanning** using Swift concurrency (TaskGroup)
- **3-phase duplicate detection**: size grouping → head hash → full hash
- **xcodegen** for project generation from `project.yml`

## License

MIT
