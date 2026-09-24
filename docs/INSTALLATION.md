# Installation Guide

## System Requirements

### macOS (Development)
- macOS 11.0 or later
- Xcode 14.0 or later
- Python 3.9 or later
- 5GB free disk space

### iOS (Target)
- iOS 16.0 or later
- iPhone with Neural Engine (A14 Bionic or newer recommended)
- 2GB free storage for model
- 4GB RAM minimum

## Development Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/iphone-offline-voice-transcriber.git
cd iphone-offline-voice-transcriber
```

### 2. Install Python Dependencies

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

### 3. Install Xcode Command Line Tools

```bash
xcode-select --install
```

Verify installation:
```bash
xcode-select --version
```

### 4. Download the Model

```bash
# Using the provided script
python3 scripts/download_model.py

# Or manual download from NGC
wget https://api.ngc.nvidia.com/v2/models/nvidia_ngc/parakeet_tdt_0_6b_v2/versions/1/files/model.onnx \
  -O models/parakeet_tdt_0.6b_v2.onnx
```

### 5. Convert Model to CoreML

```bash
# Full precision model
python3 scripts/convert_model.py \
  --onnx-model models/parakeet_tdt_0.6b_v2.onnx \
  --output models/parakeet_tdt_0.6b_v2.mlmodel

# Or quantized model (recommended)
python3 scripts/convert_model.py \
  --onnx-model models/parakeet_tdt_0.6b_v2.onnx \
  --output models/parakeet_tdt_0.6b_v2_quantized.mlmodel \
  --quantize int8
```

### 6. Copy Model to Xcode Project

```bash
mkdir -p ios/VoiceTranscriber/Resources/Models
cp models/parakeet_tdt_0.6b_v2_quantized.mlmodel \
   ios/VoiceTranscriber/Resources/Models/
```

### 7. Open iOS Project

```bash
open ios/VoiceTranscriber.xcodeproj
```

### 8. Configure Signing

In Xcode:
1. Select the VoiceTranscriber project
2. Select the VoiceTranscriber target
3. Go to Signing & Capabilities
4. Select your team
5. Set Bundle Identifier (e.g., com.yourcompany.voicetranscriber)

### 9. Build and Run

```bash
# Using Xcode
# Select your device, press Cmd + R

# Or using xcodebuild
xcodebuild -scheme VoiceTranscriber \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Docker Setup (Optional)

For consistent development environment:

```bash
# Build Docker image
docker build -t voice-transcriber .

# Run container
docker run -it -v $(pwd):/workspace voice-transcriber /bin/bash

# Inside container
cd /workspace
python3 scripts/download_model.py
python3 scripts/convert_model.py --onnx-model models/parakeet_tdt_0.6b_v2.onnx --output models/parakeet_tdt_0.6b_v2.mlmodel
```

## Troubleshooting Installation

### Issue: Python Version Mismatch

```bash
# Check Python version
python3 --version

# Should be 3.9+
# If not, install Python 3.9+
brew install python@3.11
```

### Issue: Xcode Not Found

```bash
# Install Xcode from App Store or use:
xcode-select --install

# If already installed but not in PATH:
sudo xcode-select --reset
```

### Issue: Model Download Failed

```bash
# Check internet connection
curl -I https://api.ngc.nvidia.com

# Manual download
# Visit: https://catalog.ngc.nvidia.com/orgs/nvidia_ngc/models/parakeet_tdt_0.6b_v2
# Download manually and place in models/
```

### Issue: CoreML Conversion Error

```bash
# Check coremltools version
python3 -c "import coremltools; print(coremltools.__version__)"

# Should be 7.0+
pip install --upgrade coremltools
```

### Issue: Pod Installation Failed

If using CocoaPods (optional):

```bash
cd ios
pod install
cd ..
```

## Post-Installation Verification

### 1. Verify Python Setup

```bash
python3 -c "
import torch
import onnx
import coremltools
import librosa
print('✓ All Python packages installed correctly')
"
```

### 2. Verify Model File

```bash
ls -lh models/parakeet_tdt_0.6b_v2.mlmodel
# Should show file with size ~150MB (quantized) or 600MB (full)
```

### 3. Verify Xcode Project

```bash
xcodebuild -list -project ios/VoiceTranscriber.xcodeproj
# Should show schemes and targets
```

### 4. Test on Simulator

```bash
# Start simulator
xcrun simctl create "iPhone 14" "com.apple.CoreSimulator.SimDeviceType.iPhone-14"

# Build for simulator
xcodebuild -scheme VoiceTranscriber \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

## IDE Setup

### Visual Studio Code

Install extensions:
- Swift for Visual Studio Code
- Python
- iOS App Installer

### JetBrains AppCode

1. Open project in AppCode
2. Go to Preferences → Project Settings → Build
3. Set iOS SDK

## Next Steps

1. Review [Architecture](ARCHITECTURE.md) for system design
2. Follow [Quick Start Guide](../README.md#quick-start) for first run
3. Check [Contributing Guidelines](CONTRIBUTING.md) to contribute

## Support

If you encounter issues:

1. Check [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Search [GitHub Issues](https://github.com/yourusername/iphone-offline-voice-transcriber/issues)
3. Ask in [Discussions](https://github.com/yourusername/iphone-offline-voice-transcriber/discussions)
