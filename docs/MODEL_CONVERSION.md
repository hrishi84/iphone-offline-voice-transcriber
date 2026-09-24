# Model Conversion Guide

## Overview

This guide explains how to convert the NVIDIA Parakeet TDT 0.6B v2 model from ONNX format to CoreML format suitable for iOS deployment.

## Prerequisites

```bash
# Python 3.9 or higher
python3 --version

# Install requirements
pip install -r requirements.txt
```

## Step 1: Download the Model

### Option A: From NVIDIA Model Registry

```bash
# Download Parakeet TDT 0.6B v2 from NGC
wget https://api.ngc.nvidia.com/v2/models/nvidia_ngc/parakeet_tdt_0_6b_v2/versions/1/files/model.onnx \
  -O models/parakeet_tdt_0.6b_v2.onnx
```

### Option B: Using the Download Script

```bash
python3 scripts/download_model.py \
  --model parakeet_tdt_0.6b_v2 \
  --output models/
```

Verify the model:
```bash
ls -lh models/parakeet_tdt_0.6b_v2.onnx
```

## Step 2: Prepare the Model

### Inspect Model Structure

```bash
python3 scripts/inspect_model.py \
  --model models/parakeet_tdt_0.6b_v2.onnx \
  --output model_info.json
```

This generates:
- Model input/output names and shapes
- Operator statistics
- Memory requirements

### Export Input/Output Specifications

```python
import onnx

model = onnx.load('models/parakeet_tdt_0.6b_v2.onnx')

print("Inputs:")
for input in model.graph.input:
    print(f"  {input.name}: {input.type.tensor_type.shape.dim}")

print("Outputs:")
for output in model.graph.output:
    print(f"  {output.name}: {output.type.tensor_type.shape.dim}")
```

## Step 3: Convert to CoreML

### Basic Conversion

```bash
python3 scripts/convert_model.py \
  --onnx-model models/parakeet_tdt_0.6b_v2.onnx \
  --output models/parakeet_tdt_0.6b_v2.mlmodel \
  --minimum-ios-target 16.0
```

### Conversion with Quantization

```bash
python3 scripts/convert_model.py \
  --onnx-model models/parakeet_tdt_0.6b_v2.onnx \
  --output models/parakeet_tdt_0.6b_v2_quantized.mlmodel \
  --quantize int8 \
  --minimum-ios-target 16.0
```

### Conversion Options

| Option | Default | Description |
|--------|---------|-------------|
| `--onnx-model` | Required | Path to ONNX model |
| `--output` | Required | Output CoreML model path |
| `--quantize` | None | Quantization type: `int8`, `float16` |
| `--minimum-ios-target` | 15.0 | Minimum iOS version |
| `--compute-units` | auto | CPU, CPU_AND_GPU, ALL |

## Step 4: Quantization

### INT8 Quantization

Most aggressive quantization (smallest model, fastest):

```bash
python3 scripts/quantize_model.py \
  --model models/parakeet_tdt_0.6b_v2.onnx \
  --quantization-type int8 \
  --output models/parakeet_tdt_0.6b_v2_int8.onnx
```

### Float16 Quantization

Balance between size and accuracy:

```bash
python3 scripts/quantize_model.py \
  --model models/parakeet_tdt_0.6b_v2.onnx \
  --quantization-type float16 \
  --output models/parakeet_tdt_0.6b_v2_float16.onnx
```

### Custom Quantization

```python
from scripts.quantize_model import QuantizationConfig, quantize_model

config = QuantizationConfig(
    quantization_type='int8',
    calibration_data_dir='calibration_data/',
    per_channel=True,
    optimize_model=True
)

quantize_model(
    input_model='models/parakeet_tdt_0.6b_v2.onnx',
    output_model='models/parakeet_tdt_0.6b_v2_custom.onnx',
    config=config
)
```

## Step 5: Validation

### Test the Converted Model

```bash
python3 scripts/test_model.py \
  --model models/parakeet_tdt_0.6b_v2.mlmodel \
  --test-audio test_audio.wav
```

### Compare Outputs

```bash
python3 scripts/compare_models.py \
  --original models/parakeet_tdt_0.6b_v2.onnx \
  --converted models/parakeet_tdt_0.6b_v2.mlmodel \
  --test-data test_samples/
```

Expected output:
```
Comparison Results:
- Mean Absolute Error: 0.0012
- Max Absolute Error: 0.0089
- Output Match: PASS
```

## Step 6: Integration into iOS App

### Copy Model to Project

```bash
cp models/parakeet_tdt_0.6b_v2.mlmodel \
  ios/VoiceTranscriber/Resources/Models/

# Verify in Xcode
open ios/VoiceTranscriber.xcodeproj
```

### Add to Build Phases

In Xcode:
1. Select target "VoiceTranscriber"
2. Build Phases → Copy Bundle Resources
3. Add the `.mlmodel` file

### Load in Swift

```swift
import CoreML

let modelURL = Bundle.main.url(
    forResource: "parakeet_tdt_0.6b_v2",
    withExtension: "mlmodel"
)!

let model = try parakeet_tdt_0_6b_v2(contentsOf: modelURL)
let prediction = try model.prediction(audio: audioBuffer)
```

## Performance Benchmarks

### Model Sizes

| Format | Quantization | Size |
|--------|-------------|------|
| ONNX | None | 600MB |
| CoreML | None | 620MB |
| CoreML | INT8 | 150MB |
| CoreML | Float16 | 300MB |

### Inference Speed (iPhone 14 Pro)

| Model | Device | Time |
|-------|--------|------|
| Full (CPU) | 120ms |
| Full (GPU) | 95ms |
| INT8 | 110ms |
| Float16 | 115ms |

## Troubleshooting

### Common Issues

**1. ONNX Model Not Found**
```
Error: Model file not found at <path>
Solution: Verify download and path
```

**2. Unsupported Operations**
```
Error: Unsupported ONNX operator: <op>
Solution: Update coremltools version or simplify model
```

**3. Shape Mismatch**
```
Error: Incompatible tensor shapes
Solution: Verify input audio specifications (16kHz, mono)
```

**4. Quantization Failure**
```
Error: Quantization failed
Solution: Provide calibration data or use simpler quantization
```

## Advanced Topics

### Custom Input Preprocessing

```python
import coremltools as ct

# Define custom preprocessing
preprocessing = ct.models.neural_network.PreprocessingParams.image(
    red_bias=0.0,
    green_bias=0.0,
    blue_bias=0.0
)

# Apply to model
model = ct.models.MLModel('model.mlmodel')
model.user_defined_metadata['preprocessing'] = preprocessing
model.save('model_preprocessed.mlmodel')
```

### Export Quantized INT8 Model Info

```bash
python3 -c "
import coremltools as ct
model = ct.models.MLModel('model_int8.mlmodel')
print(f'Size: {model.get_blob_file_size()} bytes')
print(f'Compute Unit: {model.compute_unit}')
"
```

## Best Practices

1. **Always validate** converted models against original
2. **Start with float16** for safety, then try INT8
3. **Test on target devices** (different iPhone models)
4. **Monitor inference latency** in real app scenarios
5. **Keep original ONNX** as reference
6. **Document calibration data** used for quantization
7. **Version your models** (include version in filename)

## References

- [CoreML Conversion Guide](https://coremltools.readme.io/)
- [ONNX GitHub](https://github.com/onnx/onnx)
- [Apple CoreML Docs](https://developer.apple.com/documentation/coreml)
