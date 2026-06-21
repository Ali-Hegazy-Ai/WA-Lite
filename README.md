# WhatsAppLite

> An unofficial, lightweight desktop wrapper for WhatsApp Web — built with **Pake** and **Tauri**.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](#license)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D6.svg)](#installation)
[![Built with](https://img.shields.io/badge/built%20with-Rust%20%2B%20Tauri-orange.svg)](#tech-stack)

WhatsAppLite packages [web.whatsapp.com](https://web.whatsapp.com) into a small, native desktop application, so you get a dedicated WhatsApp window without keeping a browser tab open. It uses your existing WhatsApp account — there's no separate sign-up or account system.

---
## Screenshots

<img width="2557" height="1437" alt="image" src="https://github.com/user-attachments/assets/f3fe563e-af71-4cdb-be2b-44e565a56b6a" />

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation (End Users)](#installation-end-users)
- [Build From Source (Developers)](#build-from-source-developers)
- [Usage](#usage)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Disclaimer](#disclaimer)
- [Acknowledgments](#acknowledgments)

---

## Features

- Lightweight desktop application (a few MB, not 100+ MB like Electron-based wrappers)
- Native Windows installer
- Dedicated WhatsApp window, separate from your browser
- Uses your existing WhatsApp account — just scan the QR code as usual
- Built with Rust and Tauri for speed and a small memory footprint
- Open source and easy to customize (icon, window size, title bar, etc.)

## Tech Stack

| Layer | Technology |
|---|---|
| Packaging tool | [Pake](https://github.com/tw93/Pake) |
| App framework | [Tauri](https://tauri.app) |
| Core language | Rust |
| Native webview (Windows) | Microsoft Edge WebView2 |
| Wrapped web app | [WhatsApp Web](https://web.whatsapp.com) |

---

## Prerequisites

You only need these if you're **building from source**. If you just want to use the app, skip to [Installation](#installation-end-users).

| Tool | Minimum version | Notes |
|---|---|---|
| [Node.js](https://nodejs.org) | 18+ (22+ recommended) | Used to run the Pake CLI / project tooling |
| [pnpm](https://pnpm.io) | Latest | `npm install -g pnpm` if you don't have it |
| [Rust](https://www.rust-lang.org/tools/install) | 1.85+ | Installed via [rustup](https://rustup.rs) |
| [Microsoft C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) | Latest | Required by the Rust/Tauri toolchain on Windows |
| [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) | Latest | Preinstalled on most up-to-date Windows 10/11 systems; install manually otherwise |

> First-time builds set up the Rust/Tauri toolchain and can take a few minutes. Subsequent builds are much faster.

---

## Installation (End Users)

1. Go to the [Releases](../../releases) page of this repository.
2. Download the latest Windows installer (`.msi` or `.exe`).
3. Run the installer and follow the prompts.
4. Launch **WhatsAppLite** from your Start Menu or desktop shortcut.
5. Scan the QR code with your phone's WhatsApp app, exactly as you would on web.whatsapp.com.

That's it — no build tools or developer setup required.

---

## Build From Source (Developers)

Clone the repository:

```bash
git clone https://github.com/ali-hegazy-ai/WhatsAppLite.git
cd WhatsAppLite
```

### Option A — Build using the included project

If this repo contains the generated Tauri project (e.g. a `src-tauri` folder and `package.json`):

```bash
# Install dependencies
pnpm i

# Run in development mode (opens a debug window)
pnpm run dev

# Build the production installer
pnpm run build
```

The finished installer will be output under `src-tauri/target/release/bundle/`.

### Option B — Rebuild from scratch with the Pake CLI

If you'd rather generate the app fresh using Pake itself:

```bash
# Install the Pake CLI globally
pnpm install -g pake-cli

# Package WhatsApp Web as a desktop app
pake https://web.whatsapp.com --name WhatsAppLite --icon ./icon.ico --width 1200 --height 800
```

Adjust the flags to match the icon and window settings you want — see [Customization](#customization) below for the full list of options.

The installer is generated in the directory you ran the command from.

---

## Usage

- Open WhatsAppLite like any other desktop app.
- Scan the QR code with your phone to link your WhatsApp account (same as web.whatsapp.com).
- Use it like a normal WhatsApp Web session — sending messages, media, and notifications work the same way, since the app is just a native shell around the official web client.
- Closing the window closes the app; reopening it keeps your linked session (the same way browser sessions persist) unless you log out from your phone.

## Customization

Because this is just a packaged web page, you can re-skin or reconfigure it by changing the Pake build options:

| Flag | Purpose |
|---|---|
| `--name` | App name shown in the title bar, Start Menu, etc. |
| `--icon` | Path or URL to a custom `.ico` (Windows), `.icns` (macOS), or `.png` (Linux) icon |
| `--width` / `--height` | Default window size |
| `--hide-title-bar` | Removes the native title bar for an immersive window |
| `--fullscreen` | Launches in fullscreen mode |

See the [Pake CLI usage guide](https://github.com/tw93/Pake) for the complete list of parameters and advanced options (style injection, ad blocking, multi-arch builds, etc.).

---

## Troubleshooting

**Build fails with a missing linker / MSVC error on Windows**
Install the [Microsoft C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) (select the "Desktop development with C++" workload) and try again.

**Blank or white window on launch**
Make sure the [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) is installed — it's required on Windows since Tauri renders through it.

**QR code keeps expiring**
This is a WhatsApp Web behavior, not specific to this app — refresh the QR code in the window the same way you would in a browser.

**Rust toolchain not found**
Install it via [rustup](https://rustup.rs), then restart your terminal so the `cargo` command is on your `PATH`.

---

## Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-improvement`)
3. Commit your changes (`git commit -m "Add my improvement"`)
4. Push to your branch (`git push origin feature/my-improvement`)
5. Open a Pull Request describing your change

For larger changes, please open an issue first to discuss what you'd like to change.

## License

This project is licensed under the [MIT License](LICENSE) — feel free to use, modify, and distribute it.

> Replace this with your actual license if it's different (e.g. GPL-3.0, since Pake itself is GPL-3.0 licensed — check Pake's license terms if you're redistributing parts of its generated project).

## Disclaimer

This project is an unofficial wrapper around WhatsApp Web and is **not affiliated with, endorsed by, or sponsored by WhatsApp or Meta**. All trademarks belong to their respective owners. Use at your own discretion, in accordance with WhatsApp's Terms of Service.

## Acknowledgments

- [Pake](https://github.com/tw93/Pake) — the CLI tool that made packaging WhatsApp Web into a desktop app effortless
- [Tauri](https://tauri.app) — the Rust-based framework powering the native shell
- [WhatsApp Web](https://web.whatsapp.com) — the service this app wraps
