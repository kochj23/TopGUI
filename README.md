# TopGUI

**A visually stunning, modern glassmorphic system monitor for macOS**

![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-2.2.0-darkblue)

TopGUI provides comprehensive real-time system monitoring with a **CleanMyMac-inspired dark blue theme** featuring a 3-column grid layout, 9 stat cards, floating colorful blobs, and glassmorphic design. Professional, beautiful, and highly informative.

## Features

### 🎨 CleanMyMac-Inspired Design
- **Dark Navy Blue Theme**: Professional dark background (rgb 0.08-0.12, 0.12-0.18, 0.22-0.32)
- **3-Column Grid Layout**: Responsive LazyVGrid with organized stat cards
- **Floating Animated Blobs**: 5 massive colorful circles (cyan, purple, pink, orange) that gently float
- **Ultra-Translucent Glass Cards**: 25% white opacity with .ultraThinMaterial blur
- **Thick White Borders**: 2px borders for strong definition on dark background
- **Dual Shadows**: Black shadow + white highlight for true 3D depth
- **Vibrant Accent Colors**: Cyan, purple, hot pink, orange, yellow, mint green
- **White Text**: High contrast for excellent readability on dark background
- **Heat Map Visualizations**: Green → yellow → orange → red
- **Modern Rounded Typography**: 32px headers with rounded San Francisco font

### 📊 Comprehensive System Monitoring (9 Stat Cards)

**Resource Monitoring:**
1. **CPU Usage**: Circular gauge with user/system/idle breakdown
2. **Memory Status**: Physical memory (used, free, wired, compressed)
3. **Load Averages**: 1min, 5min, 15min system load tracking

**Process Intelligence:**
4. **Top 5 CPU Processes**: Ranked list of CPU-intensive processes with heat map
5. **Top 5 Memory Processes**: Ranked list of memory consumers with heat map
6. **Process States**: Running/sleeping/stuck/threads breakdown

**System I/O:**
7. **Swap Usage**: Swapins and swapouts tracking
8. **Network Stats**: Packets in/out monitoring
9. **Disk I/O**: Read/write operations tracking

**Additional Features:**
- **Quick Actions Card**: Kill High CPU, Refresh, Export buttons
- **Full Process List**: Searchable, sortable table with real-time updates
- **Search & Filter**: Quick search across process names, PIDs, users
- **Sortable Columns**: Sort by PID, command, CPU%, memory%, time
- **Heat-Mapped Values**: Color-coded indicators for all metrics

### ⚙️ Process Management
- **Detailed Views**: Click any process for comprehensive statistics
- **Kill Process**: Terminate processes with confirmation
- **Change Priority**: Adjust process nice values (-20 to +20)
- **Process Stats**: View threads, ports, memory regions, and more

## Screenshots

*Dashboard View*: CleanMyMac-inspired 3-column grid with 9 stat cards, dark navy blue background, floating colorful blobs, and glassmorphic cards

*Stat Cards*: CPU gauge, Memory, Load Averages, Top 5 CPU/Memory processes, Swap, States, Network, Disk I/O

*Quick Actions*: Kill High CPU, Refresh, and Export buttons in full-width card

*Process List*: Searchable, sortable table with heat-mapped CPU and memory indicators

*Floating Blobs*: 5 massive animated circles (cyan, purple, pink, orange) creating atmospheric depth

## Installation

### From DMG (Recommended)
1. Download `TopGUI-v2.2.0-build4.dmg` from releases
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
- v2.2.0: CleanMyMac-inspired grid layout with 9 stat cards and dark blue theme
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
- Version: 2.2.0
- Build: 4
- Build Date: January 15, 2026
- Design: CleanMyMac-Inspired Dark Blue Grid Layout
- Cards: 9 stat cards + Quick Actions + Process List
- Minimum macOS: 13.0
- Architecture: Universal (Apple Silicon & Intel)
