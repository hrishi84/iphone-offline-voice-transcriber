# Architecture & Design

## Overview

The iPhone Offline Voice Transcriber consists of three main components:

1. **Model Layer**: NVIDIA Parakeet TDT 0.6B v2 speech recognition model
2. **iOS App**: Native SwiftUI application for audio capture and transcription
3. **Conversion Pipeline**: Python scripts for model optimization and conversion

## System Architecture

```
┌─────────────────────────────────────────┐
│          iOS App (SwiftUI)              │
│  ┌─────────────────────────────────┐   │
│  │   UI Layer                      │   │
│  │  (Recording, Display, Settings) │   │
│  └─────────────────────────────────┘   │
│           ↓                             │
│  ┌─────────────────────────────────┐   │
│  │  Audio Processing               │   │
│  │ (Capture, Normalize, Buffer)    │   │
│  └─────────────────────────────────┘   │
│           ↓                             │
│  ┌─────────────────────────────────┐   │
│  │  ML Inference Layer             │   │
│  │  (CoreML Model Loading & Exec)  │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
         ↓
    Device Storage
    (CoreML Model)
```

## Model Architecture

### Parakeet TDT 0.6B v2

The Transducer-based model uses:
- **Encoder**: Conformer-based acoustic feature encoder
- **Prediction Network**: RNN-based sequence predictor
- **Joint Network**: Combines encoder and prediction outputs

### Input/Output Specifications

**Input:**
- Single-channel audio at 16kHz
- Float32 samples
- Variable length sequences (typically 5-30 seconds)

**Output:**
- Text string (UTF-8 encoded)
- Confidence scores (optional)

## iOS App Structure

### Project Organization

```
ios/VoiceTranscriber/
├── App/
│   ├── VoiceTranscriberApp.swift
│   └── AppDelegate.swift
├── Views/
│   ├── ContentView.swift
│   ├── RecordingView.swift
│   ├── TranscriptionView.swift
│   └── SettingsView.swift
├── ViewModels/
│   ├── RecorderViewModel.swift
│   └── TranscriberViewModel.swift
├── Models/
│   ├── TranscriptionResult.swift
│   └── AudioBuffer.swift
├── Services/
│   ├── AudioRecorderService.swift
│   ├── TranscriptionService.swift
│   └── ModelManager.swift
├── Utilities/
│   ├── AudioProcessing.swift
│   └── ErrorHandling.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

## Data Flow

### Recording Pipeline

```
Microphone
    ↓
AVAudioEngine
    ↓
Audio Buffer (16kHz PCM)
    ↓
Audio Preprocessing
    ↓
Feature Extraction
    ↓
Model Inference
    ↓
Text Output
```

### Audio Processing

1. **Capture**: Record at 16kHz mono using AVAudioEngine
2. **Buffering**: Accumulate samples in 10ms chunks
3. **Normalization**: Scale audio to [-1, 1] range
4. **Feature Extraction**: Compute mel-spectrograms
5. **Inference**: Feed to Parakeet model
6. **Decoding**: Convert network outputs to text

## Model Conversion Pipeline

### ONNX → CoreML Conversion

```
Parakeet TDT (ONNX)
    ↓
Load with ONNXRuntime
    ↓
Quantization (optional)
    ↓
Convert to CoreML
    ↓
Optimize for iOS
    ↓
Package in App Bundle
```

### Quantization Strategy

- **INT8 Quantization**: 4x model size reduction (~600MB → 150MB)
- **Method**: Post-training static quantization
- **Impact**: ~10-15% latency reduction, <1% accuracy loss

## Performance Considerations

### Memory Management

- Model loaded once at app startup
- Input tensors allocated upfront
- Audio buffers recycled to reduce GC pressure
- Typical memory usage: 800MB - 1.2GB

### Latency Optimization

1. **Model Level**:
   - Use quantized models
   - Batch processing for multiple utterances

2. **App Level**:
   - Pre-allocate inference buffers
   - Stream audio in fixed-size chunks
   - Async inference on background threads

3. **System Level**:
   - Disable idle timer during recording
   - Use background app refresh for long sessions
   - Monitor thermal state

## Threading Model

```
Main Thread (UI)
    ↓
AudioEngine (Real-time thread)
    ↓
Inference Thread (Serial dispatch queue)
    ↓
Delegate Updates (Main thread)
```

## Error Handling

### Model Errors
- Invalid input dimensions
- Model loading failures
- Inference timeouts
- Corrupted model files

### Audio Errors
- Microphone permission denied
- Audio session interruption
- Buffer overflow
- Audio codec failures

### Recovery Strategies
- Automatic retry with exponential backoff
- Fallback to previous working state
- User notifications with actionable steps

## Future Enhancements

1. **Streaming Inference**: Process audio in real-time chunks
2. **Multi-Language**: Support additional language variants
3. **Custom Models**: Allow fine-tuning on domain-specific data
4. **On-Device Training**: Update models based on user feedback
5. **Caching**: Cache transcription results
6. **Compression**: Further model compression techniques

## References

- [NVIDIA Parakeet](https://github.com/NVIDIA/NeMo)
- [CoreML Documentation](https://developer.apple.com/coreml/)
- [AVFoundation Audio](https://developer.apple.com/documentation/avfoundation/audio)
