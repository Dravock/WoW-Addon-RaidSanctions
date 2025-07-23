# RaidSanctions - World of Warcraft Addon

A professional World of Warcraft addon for managing raid sanctions and penalties for guilds and raid groups.

## 📋 Overview

RaidSanctions is a comprehensive addon that helps raid leaders and guild officers manage penalties for various raid offenses. The addon provides a user-friendly interface for tracking penalties, automatic calculation of fines, and persistent data storage across sessions.

## ✨ Features

### 🎯 Core Functions
- **Automatic Player Detection**: Automatically detects all raid and group members
- **Predefined Penalties**: Various penalty categories with configurable amounts
- **Real-time Tracking**: Live updates of penalty counters
- **Persistent Data**: Saves all data between sessions
- **Intuitive UI**: Modern, clear user interface

### 💰 Penalty System
The addon comes with predefined penalty categories:

| Category | Amount | Description |
|----------|--------|-------------|
| **Wrong Tactic** | 30s | For tactical errors |
| **Wrong Gear** | 75s | For inappropriate equipment |
| **Late** | 1g | For being late |
| **AFK** | 50s | For unannounced absence |
| **Disruption** | 25s | For disruptive behavior |

### 🖥️ User Interface
- **Clear Table**: Shows all players with their penalty counters
- **Color Coding**: Visual distinction by penalty count
- **Class Colors**: Player names in their respective class colors
- **Action Panel**: Quick access to all penalty categories
- **Selection System**: Click-based player selection for penalties

## 🚀 Installation

### Automatic Installation (Recommended)
1. Download the addon via CurseForge Client or WoWUp
2. Restart World of Warcraft
3. Enable the addon in the addon menu

### Manual Installation
1. Download the latest version from GitHub
2. Extract the folder to:
   ```
   World of Warcraft\_retail_\Interface\AddOns\RaidSanctions\
   ```
3. Restart World of Warcraft
4. Enable "RaidSanctions" in the addon list

## 🎮 Usage

### Basic Operation

#### Open Addon
```
/rs
/sanktions
```

#### Debug Mode (for developers)
```
/rs debug
```

### Step-by-Step Guide

1. **Join Raid**: The addon automatically detects all raid/group members
2. **Open Addon**: Use `/rs` to open the main interface
3. **Select Player**: Click on a player in the list
4. **Apply Penalty**: Click on the corresponding penalty button below
5. **Keep Track**: Monitor all penalties in real-time

### UI Elements

#### Main Window
- **Player List**: Shows all raid members with penalty counters
- **Counter System**: Numerical display for each penalty category
- **Total Sum**: Automatic calculation of all penalties per player

#### Action Panel
- **Penalty Buttons**: Direct application of penalties to selected players
- **Tooltips**: Detailed information for each penalty
- **Visual Feedback**: Confirmation upon successful application

#### Additional Features
- **Add Player**: Manual addition of players
- **Reset**: Reset all session data
- **ESC Key**: Quick closing of the window

## 🔧 Configuration

### Penalty Adjustment
Penalties can be adjusted in `logic.lua`:

```lua
local penalties = {
    ["Wrong Tactic"] = 30,    -- 30 Silver
    ["Wrong Gear"] = 75,      -- 75 Silver
    ["Late"] = 100,           -- 1 Gold
    ["AFK"] = 50,             -- 50 Silver
    ["Disruption"] = 25,      -- 25 Silver
}
```

### Data Storage
The addon saves data in:
- **RaidSanctionsDB**: Global addon data
- **RaidSanctionsCharDB**: Character-specific data

## 📊 Technical Details

### Architecture
- **Modular Structure**: Separate modules for Logic, UI and Events
- **Event System**: Responds to WoW events like group changes
- **Persistence**: Automatic saving on changes

### Files
```
RaidSanctions/
├── RaidSanctions.toc     # Addon manifest
├── RaidSanctions.lua     # Main coordinator
├── logic.lua             # Business logic
├── ui.lua               # User interface
├── RaidSanctions.xml    # UI definitions
└── README.md            # This documentation
```

### Compatibility
- **WoW Version**: Retail (current version)
- **Group Size**: Supports Solo, Group (5) and Raid (40)
- **Localization**: Prepared for multiple languages

## 🐛 Troubleshooting

### Common Issues

**Problem**: Players are not displayed
- **Solution**: Use `/rs debug` to test group detection

**Problem**: Data is lost
- **Solution**: Check if SavedVariables are loaded correctly

**Problem**: UI is not displayed
- **Solution**: Make sure the addon is enabled (`/reload`)

### Debug Commands
```
/rs debug          # Shows current group members
/reload             # Reloads all addons
```

## 🤝 Contributing

Contributions are welcome! Please note:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Create a Pull Request

### Development
```bash
git clone https://github.com/Dravock/RaidSanctions.git
cd RaidSanctions
# Edit files in your WoW AddOns folder
```

## 📝 Changelog

### Version 1.1
- ✅ Improved UI with counter system
- ✅ Bottom panel for actions
- ✅ Automatic list updates
- ✅ Better color coding
- ✅ Optimized penalty application

### Version 1.0
- 🎉 First release
- ⚡ Basic penalty management
- 💾 Persistent data storage
- 🎨 Modern UI

## 📄 License

This project is under the MIT License - see [LICENSE](LICENSE) for details.

## 👤 Author

**Dravock**
- GitHub: [@Dravock](https://github.com/Dravock)

## 🙏 Acknowledgments

- World of Warcraft Community for feedback and testing
- Blizzard Entertainment for the comprehensive addon APIs
- All beta testers and contributors

---

**⚡ For optimal raid discipline and fair penalty management!**
