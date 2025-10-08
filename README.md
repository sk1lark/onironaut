# 🌙 THE ONEIRONAUT

*A meditative typing game where you explore the subconscious mind of a sleeping cosmic being.*

<div align="center">

**Status:** ✅ **PLAYABLE PROTOTYPE** (80% Complete)

[Quick Start](#quick-start) • [Documentation](#documentation) • [Features](#features) • [Development](#development)

</div>

---

## 🎮 About

**The Oneironaut** is a unique typing game that combines:
- ⌨️ **Satisfying typing mechanics** - Type words to resolve falling "phantoms"
- 🧘 **Meditative flow state** - Enter synchronicity by maintaining combos
- 📺 **Retro CRT aesthetic** - Authentic VHS-era monitor simulation
- 🌊 **Dreamlike atmosphere** - Explore abstract layers of consciousness

### The Concept
You are "The Oneironaut" - a lucid dreamer navigating the subconscious of a cosmic being. As thoughts manifest as falling phantoms, you must type their names to process them before they overwhelm your lucidity.

---

## 🚀 Quick Start

### Requirements
- **Godot 4.5** or higher
- Keyboard (gamepad support planned)

### How to Play
1. Open this project in Godot 4.5
2. Press **F5** to run
3. **Type** the words on falling phantoms to resolve them
4. Maintain your **lucidity** (health) - don't miss or mistype!
5. Complete **5 in a row** to enter **synchronicity** state

### Controls
- **Type letters** - Target and resolve phantoms
- **Backspace** - Delete last character
- **ESC** - (Pause menu - not yet implemented)

---

## ✨ Features

### ✅ Currently Implemented
- [x] Full typing detection and word matching
- [x] 13 unique Level 1 phantoms with ASCII art
- [x] Health/Lucidity system with visual feedback
- [x] Synchronicity "flow state" mechanic
- [x] Complete CRT shader with scanlines, wobble, glitch effects
- [x] Smooth animations and transitions
- [x] Game over and reset system
- [x] Pixel-perfect retro aesthetic

### 🚧 In Progress
- [ ] Audio system (framework ready, needs sound files)
- [ ] Level progression (2-5)
- [ ] Upgrade system ("Liminal" mechanics)
- [ ] Additional phantom variety

### 📋 Planned
- [ ] 5 complete levels with unique themes
- [ ] Boss phantom (The Ego)
- [ ] Save/load system
- [ ] Statistics and achievements
- [ ] Multiple difficulty modes

---

## 📚 Documentation

Comprehensive guides are included:

| Document | Purpose |
|----------|---------|
| **[ACTION_PLAN.md](ACTION_PLAN.md)** | What to do next - start here! |
| **[QUICKSTART.md](QUICKSTART.md)** | Detailed how-to-play and troubleshooting |
| **[IMPLEMENTATION_COMPLETE.md](IMPLEMENTATION_COMPLETE.md)** | Full technical summary |
| **[SETUP_STATUS.md](SETUP_STATUS.md)** | What's implemented vs. pending |
| **[AUDIO_SETUP.md](AUDIO_SETUP.md)** | How to add sound effects |

---

## 🎯 Development Status

### Core Systems (100%)
- ✅ Input handling
- ✅ Phantom spawning/movement
- ✅ Typing validation
- ✅ Health system
- ✅ Visual effects
- ✅ Game state management

### Content (30%)
- ✅ Level 1 phantoms (13 created)
- ⏳ Levels 2-5 phantoms (0/4 complete)
- ⏳ Upgrade system (0% - designed only)

### Polish (60%)
- ✅ CRT shader effects
- ✅ Animations and tweens
- ⏳ Audio (system ready, no files)
- ❌ Particle effects
- ❌ Save system

---

## 🛠️ Technical Details

### Built With
- **Engine:** Godot 4.5
- **Language:** GDScript
- **Resolution:** 640x360 (pixel-perfect scaling)
- **Font:** Monogram Extended

### Architecture
```
the-oneironaut/
├── scenes/
│   ├── main.tscn          # Complete game scene
│   ├── phantom.tscn       # Phantom entity
│   └── sound_manager.tscn # Audio system (autoload)
├── scripts/
│   ├── main.gd            # Game controller (400+ lines)
│   ├── phantom.gd         # Phantom behavior
│   ├── phantom_data.gd    # Custom resource
│   ├── sound_manager.gd   # Audio management
│   └── level_manager.gd   # Level progression
├── phantoms/              # 13 .tres resource files
└── shaders/
    └── crt_shader.gdshader # Full CRT effect
```

### Key Systems
- **Typing Engine:** Character-by-character validation with visual feedback
- **Synchronicity:** 5-combo flow state with visual changes
- **Health:** Dynamic bar scaling, damage on miss/typo
- **Visuals:** Real-time shader effects, smooth tweening

---

## 🎨 Customization

### Adjust Difficulty
Edit `scripts/main.gd`:
```gdscript
var spawn_interval: float = 3.0  # Lower = harder
```

### Create New Phantoms
1. Duplicate any `.tres` file in `phantoms/`
2. Edit:
   - `art` - ASCII design (keep short)
   - `text_to_type` - Word to type (lowercase)
   - `base_speed` - Fall speed (15-40)
3. Save and run!

### Tweak Visuals
Edit CRT shader in `scenes/main.tscn`:
- `scanline_intensity` (0-1)
- `wobble_intensity` (0-0.01)
- `screen_curve` (0-10)
- `brightness` (0-2)

---

## 🐛 Known Issues

### Expected Before First Run
- ❌ "PhantomData not found" - Normal, resolves after load
- ❌ "SoundManager not found" - Normal, autoload not loaded yet

### Confirmed Bugs
- None currently! 🎉

### Limitations
- No audio files included (system ready, needs assets)
- Only Level 1 content available
- No save/load yet

---

## 🤝 Contributing

This is a solo project currently, but feedback is welcome!

### Want to Help?
- 🎨 **Artists:** Create more phantom ASCII art
- 🎵 **Musicians:** Generate ambient soundscapes
- 🐛 **Testers:** Play and report balance issues
- 💡 **Designers:** Suggest phantom words/themes

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Credits

### Assets Used
- **Font:** [Monogram by datagoblin](https://datagoblin.itch.io/monogram)
- **Engine:** [Godot Engine](https://godotengine.org/)

### Inspiration
- Typing games: TypeRacer, ZType
- Meditative games: Tetris Effect, Electronauts
- Aesthetic: Vaporwave, Y2K, retro computing

---

## 📞 Contact

Project Link: [https://github.com/yourusername/the-oneironaut](https://github.com/yourusername/the-oneironaut)

---

<div align="center">

**Made with ☕ and lots of typing**

*Sleep well, Oneironaut. The cosmos awaits.* 🌙✨

</div>


<!-- ABOUT -->
## About The Project
<br />

[![Product Screenshot][product-screenshot]](https://waka.hackclub.com)

This tool can successfully measure time spent building your games or apps in Godot.
<br />
Here's why:
* It differentiates between switching a scene and script
* It counts key presses as coding and mouse clicks as building scene
* Changing scene structure results in a heartbeat sent
* It correctly detects OS, machine name, language, editor, files
* It can detect your cursor line and position
* Time is split between: Building, Coding, Testing
* In the future it will also detect testing your projects

It works on both Linux and Windows, it wasn't tested on macOS yet
<br />
You can also see your time spent in the editor itself:
[![Time in editor][time-screenshot]]

<p align="right">(<a href="#readme-top">top</a>)</p>


### Built Using
I used the Ouch! CLI tool for decompression of files <br />
This project was built using one simple, yet powerful language.<br />
It required a lot of workarounds, but it was a pleasure to use it
* [![GDScript][Godot]][Godot-url]
* [![Ouch!][Ouch-shield]][Ouch-url]

<p align="right">(<a href="#readme-top">top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started
How to install and use this software? It's easy!

### Installation
You can either download it from the [Godot Asset Library](https://godotengine.org/asset-library/asset/3484).
<br />Or you can manually install it, here's how to do it!
1. Clone the repository
    ```sh
    git clone https://github.com/BudzioT/Godot_Super-Wakatime.git
    ```
2. Go into your project
3. Insert the entire `./addons` folder into your project `res://` directory

<p align="right">(<a href="#readme-top">top</a>)</p>

<!-- USAGE -->
## Usage
Don't know how to use this plugin? Here are the steps:
1. Turn on the plugin in your plugins. In your `Project -> Project Settings -> Plugins -> `Click the `Enable` checkbox near this plugin
2. If prompted for API key, provide it from Wakatime website
3. if there is an issue with it, please manually create `~/.wakatime.cfg` file with these contents:
    ```sh
    [settings]
    api_key=xxxx
    ```
    Where xxxx is your api key
<br /><br />
If you are coming from High Seas used this:
    ```sh
    [settings]
    api_url = https://waka.hackclub.com/api
    api_key=xxxx
    ```
4. Wakatime CLI should have been installed automatically along with Ouch! Decompression library
5. Work on your project! You should see your results on either Wakatime or Hackatime!
6. You can also see your time at the bottom panel

<p align="right">(<a href="#readme-top">top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- URLS -->
[contributors-shield]: https://img.shields.io/github/contributors/budziot/Godot_Super-Wakatime?style=for-the-badge
[contributors-url]: https://github.com/BudzioT/Godot_Super-Wakatime/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/budziot/Godot_Super-Wakatime?style=for-the-badge
[forks-url]: https://github.com/BudzioT/Godot_Super-Wakatime/forks
[stars-shield]: https://img.shields.io/github/stars/budziot/Godot_Super-Wakatime?style=for-the-badge
[stars-url]: https://github.com/BudzioT/Godot_Super-Wakatime/stargazers
[issues-shield]: https://img.shields.io/github/issues/budziot/Godot_Super-Wakatime?style=for-the-badge
[issues-url]: https://github.com/BudzioT/Godot_Super-Wakatime/issues
[license-shield]: https://img.shields.io/github/license/budziot/Godot_Super-Wakatime?style=for-the-badge
[license-url]: https://github.com/BudzioT/Godot_Super-Wakatime/blob/master/addons/godot_super-wakatime/LICENSE
[product-screenshot]: https://cloud-j4wibbzz7-hack-club-bot.vercel.app/0image.png
[product-logo]: https://cloud-j4wibbzz7-hack-club-bot.vercel.app/2godotwaka2.png
[Godot]: https://img.shields.io/badge/Godot%20Engine-478CBF?logo=godotengine&logoColor=fff&style=flat
[Godot-url]: https://godotengine.org/
[Ouch-shield]: https://img.shields.io/badge/Ouch!-tool-blue?label=Ouch!
[Ouch-url]: https://github.com/ouch-org/ouch
[time-screenshot]: https://cloud-l88kldf50-hack-club-bot.vercel.app/0image.png
