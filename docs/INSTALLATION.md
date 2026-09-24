# Installation Guide

## System Requirements

### macOS (Development)

- macOS with Xcode 16.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An Apple Developer account (free tier is enough for on-device debug builds)

### iOS (Target)

- iOS 17.0 or later
- A **physical iPhone** with a Neural Engine (A12 Bionic or newer) — the Simulator cannot meaningfully run Parakeet TDT inference on the ANE, so simulator builds are compile checks only, not functional tests
- ~1GB free storage for the cached model
- Wi-Fi or cellular for the one-time model download

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/hrishi84/iphone-offline-voice-transcriber.git
cd iphone-offline-voice-transcriber
```

### 2. Install XcodeGen

```bash
brew install xcodegen
```

### 3. Generate the Xcode Project

```bash
cd ios
xcodegen generate
```

This reads `ios/project.yml` and produces `VoiceTranscriber.xcodeproj`. The generated project is not committed to git (it's regenerated from `project.yml`), so re-run this command whenever `project.yml` changes.

### 4. Open in Xcode

```bash
open VoiceTranscriber.xcodeproj
```

Xcode resolves the [FluidAudio](https://github.com/FluidInference/FluidAudio) Swift Package automatically on first open. If it reports a version conflict, check `packages.FluidAudio.from` in `ios/project.yml` against FluidAudio's current releases and adjust.

### 5. Configure Signing

1. Select the `VoiceTranscriber` project → the `VoiceTranscriber` target → **Signing & Capabilities**.
2. Choose your team.
3. `project.yml` ships with a placeholder bundle id prefix (`com.example`). Change `options.bundleIdPrefix` (and `PRODUCT_BUNDLE_IDENTIFIER` under the target's `settings.base`) to your own reverse-DNS prefix, then re-run `xcodegen generate`.

### 6. Build and Run

Select a physical iPhone as the destination and press `Cmd + R`, or from the command line (run from the repo root):

```bash
xcodebuild -project ios/VoiceTranscriber.xcodeproj \
  -scheme VoiceTranscriber \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  build
```

(Deploying to a specific device over `xcodebuild` requires its UDID — using Xcode's Run button is simpler for day-to-day development.)

### 7. First Run

1. Grant microphone access when prompted.
2. Stay connected to Wi-Fi/cellular while the app downloads the Parakeet TDT 0.6B v2 model (~450–600MB, one time).
3. Once loaded, try Airplane Mode — transcription should keep working.

## Running Tests

```bash
xcodebuild test \
  -project ios/VoiceTranscriber.xcodeproj \
  -scheme VoiceTranscriber \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

The test target only covers `TextCleanup` (deterministic logic) — it doesn't exercise FluidAudio or the microphone, so it's fine to run on the simulator.

## Troubleshooting

**"No such module 'FluidAudio'"**
Xcode hasn't resolved the Swift Package yet. File → Packages → Resolve Package Versions.

**Model download stalls or fails**
Check network connectivity; the download is a few hundred MB from Hugging Face. Killing and relaunching the app resumes from FluidAudio's cache, it doesn't re-download from scratch each time.

**Transcription is slow or the app is unresponsive on the Simulator**
Expected — the Simulator doesn't have a real Neural Engine. Test on a physical device.

**Signing errors**
Make sure you've set your own team and bundle identifier prefix as described in step 5; the default `com.example.VoiceTranscriber` bundle id isn't yours to sign with.

## Next Steps

- [Architecture](ARCHITECTURE.md)
- [Model Acquisition](MODEL_ACQUISITION.md)
- [Contributing](CONTRIBUTING.md)
