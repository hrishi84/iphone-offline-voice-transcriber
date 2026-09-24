# iPhone Offline Voice Transcriber

A native iOS app that transcribes speech to clean text entirely on-device, using NVIDIA's Parakeet TDT 0.6B v2 model running on the Apple Neural Engine. No internet connection required for transcription, no cloud service, no AI subscription. Inspired by [typevoice](https://github.com/warplabshq/typevoice), the macOS version of this idea.

## How it works

Speech recognition is powered by [FluidAudio](https://github.com/FluidInference/FluidAudio) (Apache 2.0), a Swift package that ships a pre-converted Core ML build of Parakeet TDT 0.6B v2 and runs it on the Apple Neural Engine. FluidAudio downloads and caches the model (~450–600MB) the first time the app runs — after that, transcription works with the device fully offline (try it in Airplane Mode).

There is no model conversion step in this repo. Earlier versions of this project tried to hand-convert Parakeet TDT from ONNX to Core ML with a Python script — that never worked, because a transducer model (encoder + prediction network + joint network + beam search decode loop) can't be converted with a single generic `coremltools.convert()` call, and the NGC URL it pointed at didn't even exist. FluidAudio's pre-built Core ML package replaces all of that.

## Features

- On-device speech-to-text using Parakeet TDT 0.6B v2
- Fully offline after the one-time model download
- No account, no subscription, no telemetry
- Deterministic rule-based text cleanup (whitespace, capitalization, filler-word removal) — no extra AI model involved
- Copy or Share the transcript into Messages, Mail, Notes, or any other app

## Requirements

- **To build**: a Mac with Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- **To run**: a physical iPhone with iOS 17.0+ and an A-series/M-series Neural Engine — the simulator cannot meaningfully run Parakeet TDT inference (Core ML falls back to CPU there and is not representative), so treat simulator builds as compile checks only
- Apple Developer account for on-device signing
- Wi-Fi or cellular for the one-time ~450–600MB model download; nothing after that

## Quick Start

```bash
brew install xcodegen
git clone https://github.com/hrishi84/iphone-offline-voice-transcriber.git
cd iphone-offline-voice-transcriber/ios
xcodegen generate
open VoiceTranscriber.xcodeproj
```

In Xcode:
1. Let Xcode resolve the FluidAudio Swift Package (first open only).
2. Select the `VoiceTranscriber` target → Signing & Capabilities → choose your team, and change the bundle identifier prefix in `ios/project.yml` (`com.example`) to your own before shipping to a device.
3. Select your iPhone as the run destination and press `Cmd + R`.
4. Grant microphone access when prompted.
5. On first launch, stay connected while the app downloads the Parakeet model. Every run after that works offline.

## Project Structure

```
iphone-offline-voice-transcriber/
├── ios/
│   ├── project.yml                    # XcodeGen manifest (generates the .xcodeproj — not committed)
│   ├── VoiceTranscriber/
│   │   ├── VoiceTranscriberApp.swift  # App entry point
│   │   ├── Models/                    # UI state enum
│   │   ├── ViewModels/                # Recording + transcription coordination
│   │   ├── Views/                     # SwiftUI screens
│   │   ├── Services/                  # Audio capture + FluidAudio integration
│   │   ├── Utilities/                 # Deterministic transcript cleanup
│   │   └── Info.plist
│   └── VoiceTranscriberTests/         # XCTest unit tests
├── docs/                              # Architecture, installation, model acquisition, contributing
└── CHANGELOG.md
```

## Using the App

1. Tap **Start** and speak.
2. Tap **Stop** — the recording is transcribed on-device.
3. Review the cleaned-up transcript, then **Copy** it or **Share** it directly into Messages, Mail, or any other app.

There is no keyboard extension or system-wide dictation replacement — iOS keyboard extensions cannot access the microphone at all, so recording always happens in this app; getting the text into another app is a copy/share away. A keyboard-extension-based workflow is listed under Roadmap below as a possible future direction (it would need the model hosted in a shared container the extension can call into).

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Model Acquisition](docs/MODEL_ACQUISITION.md)
- [Installation](docs/INSTALLATION.md)
- [Contributing](docs/CONTRIBUTING.md)

## Privacy

- All audio processing happens on-device.
- No audio or transcript is sent to a server.
- Audio is captured in memory only and never written to disk.
- No analytics, no telemetry.

## License

MIT License — see [LICENSE](LICENSE). [FluidAudio](https://github.com/FluidInference/FluidAudio) is used under Apache 2.0.

## Roadmap

- [ ] Streaming (live, as-you-speak) transcription using FluidAudio's sliding-window ASR manager
- [ ] Multilingual support via Parakeet TDT v3
- [ ] Investigate a keyboard extension / system-wide dictation replacement
- [ ] On-device punctuation/formatting presets

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
