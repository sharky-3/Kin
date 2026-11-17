# Kin

Your favorite people, right in the macOS menu bar.

Kin puts the people you talk to most in your menu bar as small avatars. Click one to send a quick message, record a voice note, or open a chat in your favorite app. Drag a file onto someone to send it to them right away.

## Features

- **People in your menu bar.** Add people from Contacts or by hand, with a photo, name, phone, email, and Telegram handle.
- **Quick messages.** Click a person to type a message and send it through Messages, WhatsApp, Telegram, Signal, FaceTime, or Mail.
- **Voice notes.** Record a voice note and Kin writes it out as text while you talk.
- **Drag and drop files.** Drag a file toward the menu bar and drop it on a person to send it with AirDrop, Messages, or Mail.
- **AirDrop nearby.** See when your people are nearby, and send files to other nearby AirDrop devices.
- **Profile photo from camera.** Take your profile picture with the built-in camera.
- **Launch at login.** Start Kin automatically when you log in.

## Requirements

- macOS 26 or later

## Installation

### 1. Install with Homebrew

```sh
brew install --cask sharky-3/kin/kin
```

### 2. Allow the app to open

If macOS blocks the first launch, open **System Settings → Privacy & Security** and select **Allow Anyway** next to the Kin security notification, if available.

### 3. Launch Kin

Open Spotlight with <kbd>⌘</kbd> <kbd>Space</kbd>, search for **Kin**, and press <kbd>Return</kbd>.

Kin lives in the menu bar and has no Dock icon. On first launch, settings open so you can add your first people.

## Updating

```sh
brew upgrade --cask kin
```

## Permissions

Kin asks for these permissions only when a feature needs them:

| Permission | Used for |
| --- | --- |
| Contacts | Adding people from your contacts |
| Camera | Taking a profile photo |
| Microphone | Recording voice notes |
| Speech Recognition | Turning voice notes into text |
| Automation (Messages) | Sending messages you type through Messages |

## Building from source

1. Clone the repository:
   ```sh
   git clone https://github.com/sharky-3/Kin.git
   cd Kin
   ```
2. Open `Kin.xcodeproj` in Xcode 26 or later.
3. Select the **Kin** scheme and press <kbd>⌘</kbd> <kbd>R</kbd>.
