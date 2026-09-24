# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Buildable iOS app via an XcodeGen `project.yml` manifest (`ios/project.yml`) — no more loose Swift files with no project to build them
- On-device transcription using [FluidAudio](https://github.com/FluidInference/FluidAudio) running NVIDIA Parakeet TDT 0.6B v2 on the Apple Neural Engine
- Live `AVAudioEngine`-based microphone capture, resampled to 16kHz mono Float32 in memory
- `TranscriptionEngine` protocol isolating the FluidAudio integration behind one file
- Deterministic rule-based transcript cleanup (`TextCleanup`: whitespace, capitalization, filler-word removal), with unit tests
- Copy and Share actions to get the transcript into Messages, Mail, or any other app
- `docs/MODEL_ACQUISITION.md` explaining FluidAudio's automatic model download/caching

### Changed
- Rewrote `ContentView.swift` to bind to a `TranscriberViewModel` instead of talking to services directly
- Rewrote README, ARCHITECTURE, INSTALLATION, and CONTRIBUTING docs around the FluidAudio/XcodeGen approach

### Removed
- The Python ONNX→Core ML conversion pipeline (`scripts/download_model.py`, `scripts/convert_model.py`, `scripts/test_model.py`, `requirements.txt`, `models/`) — it downloaded from a non-existent NGC URL and could never have converted a transducer model like Parakeet TDT with a generic `coremltools.convert()` call
- `docs/MODEL_CONVERSION.md` (superseded by `docs/MODEL_ACQUISITION.md`)
- The old `AudioRecorderService.swift`/`TranscriptionService.swift` stub pair — the latter's inference was an explicit `// TODO` placeholder, and its audio handling used an invalid `Data.withUnsafeBytes { $0.load(as: [Int16].self) }` cast that doesn't compile

### Fixed
- The app now has an actual, generatable Xcode project (`ios/project.yml` + `xcodegen generate`) instead of loose Swift files with no `.xcodeproj`

## [0.1.0] - 2024-09-24

### Added
- Project initialization
- Repository structure
- Documentation scaffolding
- Python model conversion utilities
- iOS app structure
