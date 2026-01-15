# TopGUI

**A visually stunning, modern glassmorphic system monitor for macOS**

![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-2.1.0-skyblue)

TopGUI provides real-time system monitoring with an **extreme glassmorphic interface** featuring massive floating colorful blobs, light blue gradients, and ultra-smooth animations. Inspired by modern iOS design and playful contemporary dashboards.

## Features

### 🎨 Extreme Glassmorphic Design
- **Floating Animated Blobs**: 5 massive colorful circles (orange, yellow, pink, purple) that gently float
- **Light Blue Gradient**: Soft sky blue background for airy, playful feel
- **Ultra-Translucent Cards**: 25% white opacity with .ultraThinMaterial blur
- **Thick White Borders**: 2px borders for strong definition
- **Dual Shadows**: Black shadow + white highlight for true 3D depth
- **Minimal Shadow Opacity**: 0.05 opacity for floating effect
- **Soft Colors**: Mint green, sunny yellow, coral pink, warm orange
- **Dark Text on Light**: Excellent readability with dark gray text
- **Heat Map Visualizations**: Green → yellow → orange → pink/red
- **Modern Rounded Typography**: 32px headers with rounded San Francisco font

### 📊 Real-Time System Monitoring
- **CPU Status**: Total usage with user/system/idle breakdown
- **Memory Status**: Physical memory tracking (used, free, wired, compressed)
- **Process List**: Full process table with live updates (1-second refresh)
- **Search & Filter**: Quick search across process names, PIDs, and users
- **Sortable Columns**: Sort by any metric (PID, CPU, memory, time)

### ⚙️ Process Management
- **Detailed Views**: Click any process for comprehensive statistics
- **Kill Process**: Terminate processes with confirmation
- **Change Priority**: Adjust process nice values (-20 to +20)
- **Process Stats**: View threads, ports, memory regions, and more

## Screenshots

*Dashboard View*: Extreme glassmorphism with floating colorful blobs, light blue gradient, ultra-translucent cards, and playful accents

*Process Detail*: Light, airy modal with soft colors, dual-shadow glass cards, and animated background blobs

*Floating Blobs*: 5 massive animated circles creating a dreamy, playful atmosphere

## Installation

### From DMG (Recommended)
1. Download `TopGUI-v2.1.0-build3.dmg` from releases
2. Mount the DMG and drag TopGUI.app to Applications
3. Launch TopGUI from Applications folder

### From Source
```bash
git clone https://github.com/kochj23/TopGUI.git
cd TopGUI
xcodegen generate
open TopGUI.xcodeproj
```

Build with Xcode 15+ and run on macOS 13.0+

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel processor
- Permission to execute system commands (top, kill, renice)

## How It Works

TopGUI parses output from the native macOS `top` command to gather real-time system statistics. The data is presented in a modern SwiftUI interface with glassmorphic design elements.

### Architecture
- **TopDataManager**: Executes `top` command and parses output
- **ContentView**: Main dashboard with glassmorphic cards and gradient background
- **ProcessDetailView**: Modal detail view with modern controls
- **ModernDesign**: Glassmorphic design system with purple gradients and frosted glass

## Security & Permissions

TopGUI requires the following entitlements:
- **No Sandbox**: Allows execution of system commands (top, kill, renice)
- **JIT & Unsigned Memory**: For dynamic code execution
- **Disable Library Validation**: For system tool integration

Some operations (kill, renice) may require administrator privileges for processes owned by other users.

## Development

### Project Structure
```
TopGUI/
├── TopGUI/
│   ├── TopGUIApp.swift          # App entry point
│   ├── ContentView.swift         # Main glassmorphic dashboard
│   ├── ProcessDetailView.swift   # Process detail modal
│   ├── TopDataManager.swift      # Data parsing and process control
│   ├── ProcessInfo.swift         # Data models
│   ├── ModernDesign.swift        # Glassmorphic design system
│   ├── Info.plist               # App configuration
│   └── TopGUI.entitlements      # Security entitlements
├── project.yml                   # Xcodegen configuration
└── README.md
```

### Building
```bash
# Generate Xcode project
xcodegen generate

# Build debug version
xcodebuild -project TopGUI.xcodeproj -scheme TopGUI -configuration Debug build

# Build release version
xcodebuild -project TopGUI.xcodeproj -scheme TopGUI -configuration Release build
```

### Testing
Launch the app and verify:
- [ ] CPU/memory stats update in real-time
- [ ] Process list sorts correctly
- [ ] Search filters process list
- [ ] Process detail view opens on click
- [ ] Kill process works with confirmation
- [ ] Priority adjustment applies successfully

## Roadmap

Future enhancements:
- [ ] GPU usage monitoring
- [ ] Network and disk I/O statistics
- [ ] Historical graphs and trends
- [ ] Export data (CSV, JSON)
- [ ] Process grouping and filtering presets
- [ ] Custom color themes
- [ ] Process activity alerts and notifications

## Credits

**Created by Jordan Koch**

Design inspired by modern glassmorphism trends, macOS Ventura aesthetics, and contemporary monitoring dashboards. Built with SwiftUI and love for beautiful interfaces.

**Version History:**
- v2.1.0: Extreme glassmorphism with floating colorful blobs and light theme
- v2.0.0: Modern glassmorphic redesign with purple gradients
- v1.0.0: Original LCARS Star Trek TNG-inspired design

## License

MIT License

Copyright (c) 2026 Jordan Koch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Support

For issues, feature requests, or contributions, please open an issue on GitHub.

---

**Build Information:**
- Version: 2.1.0
- Build: 3
- Build Date: January 15, 2026
- Design: Extreme Glassmorphic with Floating Blobs
- Minimum macOS: 13.0
- Architecture: Universal (Apple Silicon & Intel)
