# TopGUI

**Advanced System Monitor with AI-Powered Insights & Glassmorphic Design**

![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-3.7.0-brightgreen)
![AI](https://img.shields.io/badge/AI-5%20Cloud%20Providers-purple)

---

![TopGUI](Screenshots/main-window.png)


## Overview

TopGUI is a beautiful, modern system monitor for macOS featuring a CleanMyMac-inspired glassmorphic design. Every stat card is clickable for detailed analytics. Includes AI-powered insights with support for 5 cloud providers.

---

## Features

### System Monitoring Dashboard (13 Interactive Cards)

| Card | Description | Click for Details |
|------|-------------|-------------------|
| **CPU & GPU** | Real-time CPU/GPU usage with dual circular gauges | User/System/Idle breakdown, GPU utilization |
| **Memory** | Physical memory usage with visual gauge | Used/Free/Wired/Compressed breakdown |
| **Load Averages** | 1/5/15 minute system load | Load per core, historical trends |
| **Disk Throughput** | Live read/write speeds (MB/s) | IOPS, session totals, activity level |
| **Top Memory** | Top 5 memory-consuming processes | Full top 10 with percentages |
| **Swap Usage** | Virtual memory paging activity | Swapins/Swapouts, total swap |
| **Process States** | Running/Sleeping/Stuck breakdown | Full state distribution, thread counts |
| **Memory Pressure** | Active/Inactive/Wired pages | Page faults, COW, compressions |
| **CPU Info** | Core count, thread count | Architecture details |
| **Disk Usage** | Storage capacity per volume | Mount points, filesystem types |
| **Network** | Download/Upload bandwidth | Per-interface stats, packet counts |
| **System Health** | Overall health score (0-100%) | CPU/Memory/Disk health breakdown |
| **Per-Core CPU** | All CPU cores in grid view | Individual core utilization |

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
- **IBM Watson** - NLU, Speech, Discovery

### Local AI Support
- **Ollama** - Free, local, private
- **MLX** - Apple Silicon optimized
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

## Version History

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
- Apple Silicon or Intel Mac
- 100MB disk space
- Internet for cloud AI (optional)

---

## Development

**Author:** Jordan Koch ([@kochj23](https://github.com/kochj23))

**Built with:**
- SwiftUI
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
