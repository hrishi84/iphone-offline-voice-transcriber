# Model Acquisition

## There is no conversion step

An earlier version of this project tried to download NVIDIA Parakeet TDT 0.6B v2 from NGC as ONNX and hand-convert it to Core ML with `coremltools.convert()`. That never worked, for two reasons:

1. The NGC URL it downloaded from didn't exist.
2. Even with a real ONNX export, a generic conversion call can't handle a transducer model like Parakeet TDT — it's an encoder, a prediction network, a joint network, and a beam-search decode loop, not a single feed-forward graph. Converting it correctly requires purpose-built conversion work, not a one-line `ct.convert()`.

That whole pipeline (`scripts/`, `requirements.txt`, `models/`) has been removed.

## What this app uses instead

[FluidAudio](https://github.com/FluidInference/FluidAudio) (Apache 2.0) already did that conversion work and publishes the result on Hugging Face as [`FluidInference/parakeet-tdt-0.6b-v2-coreml`](https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v2-coreml). This is the same approach [typevoice](https://github.com/warplabshq/typevoice) (the macOS app this project is modeled on) uses.

At runtime, `FluidAudioTranscriptionEngine.loadModels()` calls:

```swift
let models = try await AsrModels.downloadAndLoad(version: .v2)
```

which:

- Downloads the pre-converted Core ML package (~450–600MB) from Hugging Face the first time it's called.
- Caches it locally on the device.
- On every later call, loads straight from cache — no network required.

## What this means for you

- **First launch needs a network connection.** Keep the device on Wi-Fi (or cellular) until the download finishes.
- **Every launch after that works offline.** Turn on Airplane Mode and transcription still works — that's the whole point.
- **Nothing to run manually.** There's no `download_model.py` or `convert_model.py` to invoke; the app handles it.

## If you want a different model version

FluidAudio also publishes a multilingual v3 build (`AsrModelVersion.v3`, 25 European languages). This app deliberately uses `.v2` for now, matching the model the user asked for and what typevoice uses. Switching is a one-line change in `FluidAudioTranscriptionEngine.swift`.
