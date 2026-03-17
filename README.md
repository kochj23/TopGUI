# TopGUI

![Build](https://github.com/kochj23/TopGUI/actions/workflows/build.yml/badge.svg)

**Advanced System Monitor with AI-Powered Insights & Glassmorphic Design**

![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-3.8.0-brightgreen)
![AI](https://img.shields.io/badge/AI-5%20Cloud%20Providers-purple)
![Widget](https://img.shields.io/badge/Widget-WidgetKit-cyan)

---

![TopGUI](Screenshots/main-window.png)


## Overview

TopGUI is a beautiful, modern system monitor for macOS featuring a CleanMyMac-inspired glassmorphic design. Every stat card is clickable for detailed analytics. Includes AI-powered insights with support for 5 cloud providers. Now with a **WidgetKit widget** for at-a-glance system stats!

---

## Features

### System Monitoring Dashboard (13 Interactive Cards)

| Card | Description | Click for Details |
|------|-------------|-------------------|
| **CPU & GPU (Graphics Processing Unit)** | Real-time CPU/GPU usage with dual circular gauges | User/System/Idle breakdown, GPU utilization |
| **Memory** | Physical memory usage with visual gauge | Used/Free/Wired/Compressed breakdown |
| **Load Averages** | 1/5/15 minute system load | Load per core, historical trends |
| **Disk Throughput** | Live read/write speeds (MB/s) | IOPS (Input/Output Operations Per Second), session totals, activity level |
| **Top Memory** | Top 5 memory-consuming processes | Full top 10 with percentages |
| **Swap Usage** | Virtual memory paging activity | Swapins/Swapouts, total swap |
| **Process States** | Running/Sleeping/Stuck breakdown | Full state distribution, thread counts |
| **Memory Pressure** | Active/Inactive/Wired pages | Page faults, COW (Copy-on-Write), compressions |
| **CPU Info** | Core count, thread count | Architecture details |
| **Disk Usage** | Storage capacity per volume | Mount points, filesystem types |
| **Network** | Download/Upload bandwidth | Per-interface stats, packet counts |
| **System Health** | Overall health score (0-100%) | CPU/Memory/Disk health breakdown |
| **Per-Core CPU** | All CPU cores in grid view | Individual core utilization |

### WidgetKit Widget (NEW in v3.8.0)

The TopGUI widget brings system monitoring to your desktop with three sizes:

| Size | Stats Displayed |
|------|-----------------|
| **Small** | CPU usage, Memory usage, Health score |
| **Medium** | CPU/Memory gauges, Top process, Health status |
| **Large** | All gauges (CPU, Memory, GPU, Health), CPU/Memory details, Top process, Process count |

**Widget Features:**
- Real-time sync with main app (every 10 seconds)
- Matching dark glassmorphic design
- Heat-mapped colors for quick status recognition
- App Group data sharing (`group.com.jkoch.topgui`)
- Updates automatically every 5 minutes

**Adding the Widget:**
1. Right-click on desktop > Edit Widgets
2. Search for "TopGUI"
3. Choose Small, Medium, or Large size
4. Drag to desktop

### Design Features
- **Glassmorphic UI** - Floating colorful blobs with blur effects
- **Dark Blue Theme** - CleanMyMac-inspired professional appearance
- **Smooth Animations** - Spring-animated gauges and transitions
- **Heat-Mapped Colors** - Green/Yellow/Orange/Red based on load
- **Real-time Updates** - 2-second refresh interval

### AI-Powered Insights
- **Process Analysis** - AI explains high CPU/memory usage
- **Optimization Tips** - Smart recommendations
- **Anomaly Detection** - Unusual pattern alerts
- **Natural Language** - Ask questions about your system

### Cloud AI Integration (5 Providers)
- **OpenAI** - GPT-4o for advanced analysis
- **Google Cloud AI** - Vertex AI, Vision, Speech
- **Microsoft Azure** - Cognitive Services
- **AWS AI Services** - Bedrock, Rekognition, Polly
- **IBM Watson** - NLU (Natural Language Understanding), Speech, Discovery

### Local AI Support
- **Ollama** - Free, local, private
- **MLX (Machine Learning eXtensions)** - Apple Silicon optimized
- **TinyLLM** - Lightweight models
- **OpenWebUI** - Self-hosted

### Ethical AI Safeguards
- Comprehensive content monitoring
- Prohibited use detection
- Automatic blocking of harmful content
- Privacy-first design
- Usage logging (hashed)

---

## Installation

```bash
# From source
cd "/Volumes/Data/xcode/TopGUI"
xcodebuild -scheme TopGUI -configuration Release build

# Copy to Applications
cp -R ~/Library/Developer/Xcode/DerivedData/TopGUI-*/Build/Products/Release/TopGUI.app /Applications/

# Launch
open /Applications/TopGUI.app
```

### AI Backend Setup (Optional)
```bash
# Install Ollama for local AI
brew install ollama
ollama serve
ollama pull mistral:latest
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+1` - `Cmd+9` | Switch AI backend |
| `Cmd+I` | Open AI Insights |
| `Cmd+R` | Refresh stats |
| `Cmd+,` | Settings |

---

## Architecture

### Widget Data Sharing

The widget uses App Groups for data sharing:

```
TopGUI (Main App)
    |
    +-- TopDataManager.swift
    |       Monitors system stats
    |       Calls syncToWidget() every 10 seconds
    |
    +-- Shared/SharedDataManager.swift
    |       Saves WidgetSystemStats to App Group
    |       Uses UserDefaults + file backup
    |
    +-- App Group: group.com.jkoch.topgui
            |
TopGUI Widget (Extension)
    |
    +-- TopGUIWidget.swift
    |       WidgetKit configuration
    |       Small/Medium/Large views
    |
    +-- SharedDataManager.swift
            Reads stats from App Group
```

### File Structure

```
TopGUI/
├── TopGUI/                      # Main app
│   ├── TopGUIApp.swift
│   ├── ContentView.swift
│   ├── TopDataManager.swift     # Updated: widget sync
│   ├── ProcessInfo.swift
│   └── ...
├── TopGUI Widget/               # Widget extension
│   ├── TopGUIWidget.swift       # Widget views & config
│   ├── WidgetData.swift         # Data models
│   ├── SharedDataManager.swift  # App Group access
│   ├── Info.plist
│   └── TopGUI_Widget.entitlements
├── Shared/                      # Shared code
│   ├── WidgetData.swift
│   └── SharedDataManager.swift
└── TopGUI.xcodeproj
```

---

## Version History

### v3.8.0 (February 4, 2026)
- **NEW: WidgetKit Widget** - Small, Medium, Large sizes
- Widget shows CPU, Memory, GPU, Health, Top Process
- App Group data sharing for real-time sync
- Main app syncs to widget every 10 seconds
- Matching dark glassmorphic design
- Version bump to 3.8.0, build 14

### v3.7.0 (February 2, 2026)
- Added Disk Throughput card with real-time read/write speeds
- All 13 cards now clickable with detailed views
- Renamed from "Top CPU" to "Disk Throughput" card
- Fixed ProcessInfo namespace conflict
- Added Color(hex:) extension for custom colors

### v3.6.0 (January 26, 2026)
- Added 5 cloud AI providers
- Added Ethical AI Guardian safeguards
- Enhanced AI backend status menu
- Auto-fallback system for AI backends

### v3.5.0 (January 2026)
- Initial public release
- 12 monitoring cards
- Glassmorphic design
- AI insights integration

---

## Requirements

- macOS 13.0 (Ventura) or later
- macOS 14.0+ for widget (Sonoma)
- Apple Silicon or Intel Mac
- 100MB disk space
- Internet for cloud AI (optional)

---

## Development

**Author:** Jordan Koch ([@kochj23](https://github.com/kochj23))

**Built with:**
- SwiftUI
- WidgetKit
- Combine
- Foundation
- CoreGraphics
- Natural Language framework

---

## License

MIT License - See [LICENSE](./LICENSE) file

**Ethical Usage Required** - See [ETHICAL_AI_TERMS_OF_SERVICE.md](./ETHICAL_AI_TERMS_OF_SERVICE.md)

---

**TopGUI - Beautiful System Monitoring with AI Intelligence**

Copyright 2026 Jordan Koch. All rights reserved.

---

## More Apps by Jordan Koch

| App | Description |
|-----|-------------|
| [NMAPScanner](https://github.com/kochj23/NMAPScanner) | Network security scanner with AI threat detection |
| [RsyncGUI](https://github.com/kochj23/RsyncGUI) | Native macOS GUI for rsync file synchronization |
| [ExcelExplorer](https://github.com/kochj23/ExcelExplorer) | Native macOS Excel/CSV file viewer |
| [DotSync](https://github.com/kochj23/DotSync) | Configuration file synchronization across machines |
| [icon-creator](https://github.com/kochj23/icon-creator) | App icon set generator for all Apple platforms |

> **[View all projects](https://github.com/kochj23?tab=repositories)**

---

> **Disclaimer:** This is a personal project created on my own time. It is not affiliated with, endorsed by, or representative of my employer.

## Nova / Claude API Integration

This app exposes a local HTTP API on port **37443** for integration with [Nova](https://github.com/kochj23) (OpenClaw AI) and Claude Code.

**Platform:** macOS  
**Auth:** None (loopback only — macOS apps bind to 127.0.0.1)

### Standard Endpoints

```bash
curl http://127.0.0.1:37443/api/status   # App status + uptime
curl http://127.0.0.1:37443/api/ping     # Health check
```

### App-Specific Endpoints

```
/api/processes
/api/system
/api/processes/kill (POST with {pid})
```

### Usage Example

```bash
# Check if running
curl -s http://127.0.0.1:37443/api/status | python3 -m json.tool

# From Nova (OpenClaw TUI)
# Nova has this pre-authorized and will use these endpoints automatically
```

The API server starts automatically when the app launches and binds to loopback only — no external network exposure.

