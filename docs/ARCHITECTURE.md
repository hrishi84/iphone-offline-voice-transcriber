# Architecture & Design

## Overview

The app has three parts:

1. **Audio capture** — `AVAudioEngine` records the microphone and resamples it to 16kHz mono Float32 in memory.
2. **On-device ASR** — [FluidAudio](https://github.com/FluidInference/FluidAudio) runs NVIDIA Parakeet TDT 0.6B v2 (a pre-converted Core ML package) on the Apple Neural Engine.
3. **Cleanup & UI** — a small set of deterministic rules clean up the raw transcript, and SwiftUI renders it with Copy/Share actions.

There is no model conversion pipeline in this repo — see [Model Acquisition](MODEL_ACQUISITION.md) for why.

## Data Flow

```
Microphone
    ↓
AVAudioEngine tap (native hardware format)
    ↓
AVAudioConverter → 16kHz mono Float32 samples (in memory)
    ↓
FluidAudio.AsrManager.transcribe(samples:)
    ↓
Parakeet TDT 0.6B v2 on the Apple Neural Engine
    ↓
Raw transcript text
    ↓
TextCleanup (whitespace, capitalization, filler-word removal)
    ↓
SwiftUI transcript view → Copy / Share
```

## iOS App Structure

```
ios/VoiceTranscriber/
├── VoiceTranscriberApp.swift        # @main entry point
├── Models/
│   └── TranscriberState.swift       # idle / downloadingModel / recording / transcribing / result / error
├── ViewModels/
│   └── TranscriberViewModel.swift   # Coordinates recording + transcription, publishes TranscriberState
├── Views/
│   └── ContentView.swift            # Record/stop button, transcript display, Copy/Share
├── Services/
│   ├── AudioRecorderService.swift   # AVAudioEngine capture → [Float] samples
│   ├── TranscriptionEngine.swift    # Protocol isolating the ASR backend
│   └── FluidAudioTranscriptionEngine.swift  # FluidAudio-backed conformance
├── Utilities/
│   └── TextCleanup.swift            # Deterministic transcript cleanup
└── Info.plist
```

`TranscriptionEngine` exists as a seam between the app and FluidAudio: everything else in the app talks to the protocol, not to FluidAudio types directly, so the ASR backend can be swapped or its exact API adjusted in one file.

## Model Loading & Caching

`FluidAudioTranscriptionEngine.loadModels()` calls `AsrModels.downloadAndLoad(version: .v2)`, which downloads Parakeet TDT 0.6B v2 from Hugging Face on first use and caches it locally. Every subsequent call reads from the cache — no network access is needed once the model is present, which is what makes offline transcription possible.

## Threading

- Audio capture runs on the real-time audio thread (the `AVAudioEngine` tap callback); converted samples are appended to a buffer under a serial dispatch queue.
- Model download and inference run as Swift `async` work off the main actor.
- `TranscriberViewModel` is `@MainActor` and publishes state changes that SwiftUI observes directly — no manual thread hopping in the view layer.

## Error Handling

- Microphone permission denial, audio engine start failures, and "no audio captured" are surfaced as `AudioRecorderError` cases.
- Model load/transcription failures are surfaced as `TranscriptionEngineError` cases (or whatever FluidAudio itself throws).
- All errors reach the UI as a single `.error(String)` state with a human-readable message and a banner in `ContentView`.

## Why Not a Keyboard Extension

iOS keyboard extensions cannot request microphone access under any circumstance, so a system-wide "voice keyboard" isn't possible without a separate host app doing the recording — which is effectively what this app already is. Getting text from this app into another app (e.g. Messages) is a Copy or Share action away.

## Future Enhancements

- Streaming transcription via FluidAudio's sliding-window ASR manager, instead of record-then-transcribe
- Multilingual support via Parakeet TDT v3
- On-device punctuation/formatting presets
