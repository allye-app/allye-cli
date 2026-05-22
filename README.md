# allye-cli

Install and update the **allye** terminal tool — a TUI/CLI for managing your Allye workspace.

## Install

```bash
curl -fsSL https://allye.app/install.sh | bash
```

## Manual install

Download the latest binary for your platform from [Releases](https://github.com/allye-app/allye-cli/releases).

| Platform | File |
|----------|------|
| Linux x86_64 | `allye_*_linux_amd64.tar.gz` |
| Linux ARM64 | `allye_*_linux_arm64.tar.gz` |
| macOS x86_64 | `allye_*_darwin_amd64.tar.gz` |
| macOS ARM64 (Apple Silicon) | `allye_*_darwin_arm64.tar.gz` |
| Windows | `allye_*_windows_amd64.zip` |

## Usage

```bash
allye          # open interactive TUI
allye --help   # list available commands
allye version  # show installed version
```

## Updates

allye updates itself automatically in the background. You'll see a notification when an update is ready — just restart your session to apply it.
