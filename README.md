# WhatsAppLite

> An unofficial, lightweight desktop wrapper for WhatsApp Web — built with **Pake** and **Tauri**.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](#license)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D6.svg)](#installation-end-users)
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
- Single standalone `.exe` — no installer, no setup wizard
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

You only need these if you're **building from source**. If you just want to use the app, skip to [Installation (End Users)](#installation-end-users).

| Tool | Minimum version | Notes |
|---|---|---|
| [Node.js](https://nodejs.org) | 18+ (22+ recommended) | Used to run the Pake CLI / project tooling |
| [pnpm](https://pnpm.io) | Latest | `npm install -g pnpm` if you don't have it |
| [Rust](https://www.rust-lang.org/tools/install) | 1.85+ | Installed via [rustup](https://rustup.rs) |
| [Microsoft C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) | Latest | Required by the Rust/Tauri toolchain on Windows |
| [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) | Latest | Preinstalled on most up-to-date Windows 10/11 systems; install manually otherwise |
| Windows **Long Paths** setting | Enabled | Required — see [Step 0: Enable Long Paths](#step-0--enable-long-paths-on-windows-critical) below |

> First-time builds set up the Rust/Tauri toolchain and can take a few minutes. Subsequent builds are much faster.
>
> Don't want to do any of this by hand? Use the [Quick Build script](#quick-build-automated-script) instead — it automates this entire section.

---

## Installation (End Users)

1. Go to the [Releases](../../releases) page of this repository.
2. Download `WhatsAppLite.exe` from the latest release.
3. Double-click `WhatsAppLite.exe` to launch it — there's **no installer or setup wizard**, the `.exe` is the fully compiled app itself.
4. (Optional) Move it to a folder of your choice and create a desktop/Start Menu shortcut yourself, since there's no installer to do this for you.
5. Scan the QR code with your phone's WhatsApp app, exactly as you would on web.whatsapp.com.

That's it — no build tools or developer setup required.

---

## Build From Source (Developers)

This produces a single standalone `WhatsAppLite.exe` — **not** an `.msi`/installer-based package. There's no setup wizard, no Start Menu entry, and no uninstaller; you just copy the `.exe` wherever you want and run it. To "uninstall," delete the file.

### Quick Build (automated script)

If you'd rather not run each step by hand, there's a `build.ps1` script in this repo that automates the entire process below: it checks/enables Long Paths, checks/installs Node, pnpm, and the Pake CLI, verifies Rust/MSVC/WebView2 are present, and runs the final build command.

1. Download or clone this repo so you have `build.ps1` locally.
2. Open PowerShell in that folder.
3. If you've never run a local script before, allow it once:
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
4. Run it:
   ```powershell
   .\build.ps1
   ```
   Or with a custom icon/name/size:
   ```powershell
   .\build.ps1 -AppName "WhatsAppLite" -IconPath ".\icon.ico" -Width 1200 -Height 800
   ```

The script skips any step that's already satisfied, so it's safe to re-run. If it stops at Long Paths and asks to reboot, reboot and just run `.\build.ps1` again — it'll pick up where it left off.

If you'd rather understand or run each step yourself, the full manual walkthrough is below.

### What you're installing and why

| Tool | What it's for |
|---|---|
| **Windows Long Paths setting** | Prevents build failures caused by Rust/Cargo/pnpm's deeply nested file paths |
| **Node.js** | Runs the Pake CLI (a Node.js program) |
| **pnpm** | Package manager used to install the Pake CLI |
| **Rust + Cargo** | Pake actually compiles a real Rust/Tauri app under the hood |
| **Microsoft C++ Build Tools** | Needed by Rust to compile native Windows binaries |
| **WebView2 Runtime** | The native browser engine the final app uses to render WhatsApp Web |

You set up all of these once. After that, building the app is a single command.

---

### Step 0 — Enable Long Paths on Windows (critical)

**Do this before installing anything else.** Skipping this is one of the most common causes of mysterious build failures with Rust/Cargo/Tauri/pnpm projects on Windows.

1. Open **Command Prompt** or **PowerShell as Administrator**.
2. Run:
   ```
   reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1 /f
   ```
3. **Reboot your computer** — this setting does not take effect until you restart.

#### Why is this necessary?

Windows historically imposed a `MAX_PATH` limit of approximately 260 characters for many applications. Modern Rust, Cargo, Tauri, npm, and pnpm projects often generate extremely deep directory structures during compilation.

For example:

```
C:\Users\pc\AppData\Local\pnpm\store\v11\links\@\pake-cli\...
```

Paths like this can easily exceed the old 260-character limit, causing builds to fail with confusing "file not found" or "cannot create file" errors that have nothing to do with your actual code.

This is a widely recommended setting for developers working with:

- Rust / Cargo
- Tauri
- Node.js / npm / pnpm
- Android Studio / Gradle
- Large Git repositories

Additional reading:

- Microsoft: https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation
- Gal Hagever: https://gal.hagever.com/posts/windows-long-paths-in-rust

---

### Step 1 — Install Node.js

1. Go to https://nodejs.org
2. Download the **LTS** version (22.x or newer recommended, 18.x minimum).
3. Run the installer, accept the defaults, and click through to finish.
4. Verify it worked — open **Command Prompt** or **PowerShell** and run:
   ```bash
   node -v
   ```
   You should see something like `v22.11.0`. If you get `'node' is not recognized`, restart your terminal (or your PC) and try again — Node adds itself to PATH, but existing terminal windows won't see it until reopened.

---

### Step 2 — Install pnpm

In the same terminal:
```bash
npm install -g pnpm
```
Verify:
```bash
pnpm -v
```
Expect a version number like `9.12.0`.

---

### Step 3 — Install Rust (via rustup)

1. Go to https://rustup.rs
2. Download `rustup-init.exe` and run it.
3. A console window opens asking how you want to proceed — press **Enter** to accept the default installation (option 1).
4. Wait for it to finish downloading and installing the stable toolchain.
5. **Close and reopen your terminal** (Rust modifies PATH — old windows won't pick it up).
6. Verify:
   ```bash
   rustc --version
   cargo --version
   ```
   You should see version numbers like `rustc 1.85.0` and `cargo 1.85.0`. If `cargo` isn't found, restart your PC — this fixes PATH issues on Windows 99% of the time.

---

### Step 4 — Install Microsoft C++ Build Tools

Rust needs a native linker on Windows, which comes from Visual Studio's Build Tools (you do **not** need the full Visual Studio IDE).

1. Go to https://visualstudio.microsoft.com/visual-cpp-build-tools/
2. Click **Download Build Tools**.
3. Run the installer. When the workload selector appears:
   - ✅ Check **"Desktop development with C++"**
   - Leave the default optional components as-is unless you know you need otherwise.
4. Click **Install** (this is the largest download, roughly 6–8 GB — grab a coffee).
5. Restart your computer once installation finishes.

> If you skip this step, your build will fail later with an error mentioning `link.exe not found` or `error: linker 'link.exe' not found`.

---

### Step 5 — Install the WebView2 Runtime

Most Windows 10/11 systems already have this preinstalled (it ships with modern Windows updates and Edge). To be safe:

1. Go to https://developer.microsoft.com/en-us/microsoft-edge/webview2/
2. Under "Evergreen Bootstrapper," download and run the installer.
3. It installs silently in a few seconds — no visible confirmation needed.

> Skipping this can cause a **blank white window** when you later launch the built app.

---

### Step 6 — Install the Pake CLI

Back in your terminal:
```bash
pnpm install -g pake-cli
```
Verify:
```bash
pake --version
```

> The first time you run any `pnpm install -g` command, Windows may show a security prompt, or PowerShell may block script execution. If you see an error like `cannot be loaded because running scripts is disabled on this system`, open PowerShell **as Administrator** and run:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> ```
> then retry.

---

### Step 7 — (Optional) Get an icon

If you want a custom icon instead of the Pake default:

1. Find or create a `.ico` file (Windows icon format — you can convert a `.png` at https://icoconvert.com).
2. Save it somewhere easy to reference, e.g. `C:\Users\You\Downloads\icon.ico`.

If you skip this, just omit the `--icon` flag below and Pake will use its default icon.

---

### Step 8 — Build the app

In your terminal, navigate to wherever you want the output to be created (e.g. your Desktop), then run:

```bash
pake https://web.whatsapp.com --name WhatsAppLite --icon ./icon.ico --width 1200 --height 800
```

What happens:

1. Pake downloads a Tauri project template (first run only — can take a few minutes).
2. It compiles the Rust/Tauri app pointing at `web.whatsapp.com`.
3. You'll see a lot of `cargo` compilation output scroll by — this is normal and can take 3–10 minutes on a first build.
4. When it finishes, it prints the path to the generated `.exe`, something like:
   ```
   ✔ Build success!
   Binary: C:\Users\You\Desktop\WhatsAppLite.exe
   ```

---

### Step 9 — Run the app

1. Double-click `WhatsAppLite.exe` — it launches immediately, no install step.
2. Scan the QR code with your phone's WhatsApp app, same as web.whatsapp.com.
3. To "uninstall," just delete the `.exe` — there's nothing else on disk to clean up.

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
| `--name` | App name shown in the title bar, etc. |
| `--icon` | Path or URL to a custom `.ico` (Windows), `.icns` (macOS), or `.png` (Linux) icon |
| `--width` / `--height` | Default window size |
| `--hide-title-bar` | Removes the native title bar for an immersive window |
| `--fullscreen` | Launches in fullscreen mode |

See the [Pake CLI usage guide](https://github.com/tw93/Pake) for the complete list of parameters and advanced options (style injection, ad blocking, multi-arch builds, etc.).

---

## Troubleshooting

**Build fails with weird "file not found" / "cannot create file" errors, especially deep inside `pnpm` or `cargo` folders**
You likely haven't enabled Long Paths. See [Step 0](#step-0--enable-long-paths-on-windows-critical), then reboot and try again.

**Build fails with a missing linker / MSVC error on Windows**
Install the [Microsoft C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) (select the "Desktop development with C++" workload) and try again.

**Blank or white window on launch**
Make sure the [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) is installed — it's required on Windows since Tauri renders through it.

**QR code keeps expiring**
This is a WhatsApp Web behavior, not specific to this app — refresh the QR code in the window the same way you would in a browser.

**Rust toolchain not found**
Install it via [rustup](https://rustup.rs), then restart your terminal so the `cargo` command is on your `PATH`.

**`'node'` / `'pnpm'` / `'cargo'` not recognized**
Close and reopen your terminal, or restart your PC — these tools modify PATH and existing terminal windows won't see the change until reopened.

**`running scripts is disabled on this system` (PowerShell)**
Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

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
