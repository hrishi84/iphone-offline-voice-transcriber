#!/usr/bin/env python3
"""
Convert ONNX model to CoreML format for iOS deployment.

This script handles:
- ONNX model loading and validation
- Optional quantization (INT8, Float16)
- Conversion to CoreML format
- Model optimization for iOS
"""

import argparse
import logging
from pathlib import Path
from typing import Optional

try:
    import onnx
    import coremltools as ct
    from onnxruntime import InferenceSession
except ImportError:
    print("Error: Required packages not installed")
    print("Install with: pip install -r requirements.txt")
    exit(1)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def validate_onnx_model(model_path: str) -> bool:
    """Validate ONNX model integrity."""
    try:
        model = onnx.load(model_path)
        onnx.checker.check_model(model)
        logger.info(f"✓ ONNX model validated: {model_path}")
        return True
    except Exception as e:
        logger.error(f"✗ ONNX validation failed: {e}")
        return False


def inspect_model(model_path: str) -> dict:
    """Extract model information."""
    model = onnx.load(model_path)

    info = {
        "inputs": [],
        "outputs": [],
        "operator_count": len(model.graph.node),
    }

    for input_tensor in model.graph.input:
        info["inputs"].append({
            "name": input_tensor.name,
            "shape": [d.dim_value for d in input_tensor.type.tensor_type.shape.dim],
        })

    for output_tensor in model.graph.output:
        info["outputs"].append({
            "name": output_tensor.name,
            "shape": [d.dim_value for d in output_tensor.type.tensor_type.shape.dim],
        })

    return info


def convert_onnx_to_coreml(
    onnx_model_path: str,
    output_path: str,
    minimum_ios_target: str = "16.0",
    compute_units: str = "auto",
) -> bool:
    """Convert ONNX model to CoreML."""
    try:
        logger.info(f"Loading ONNX model: {onnx_model_path}")
        model_spec = ct.convert(
            onnx_model_path,
            convert_to="mlmodel",
            minimum_ios_deployment_target=minimum_ios_target,
            compute_units=compute_units,
        )

        logger.info(f"Saving CoreML model: {output_path}")
        model_spec.save(output_path)

        logger.info(f"✓ Conversion successful")
        logger.info(f"  Output: {output_path}")
        logger.info(f"  Size: {Path(output_path).stat().st_size / 1e6:.2f} MB")

        return True

    except Exception as e:
        logger.error(f"✗ Conversion failed: {e}")
        return False


def quantize_before_conversion(
    onnx_model_path: str,
    output_path: str,
    quantization_type: str = "int8",
) -> Optional[str]:
    """Quantize ONNX model before conversion."""
    try:
        from onnxruntime.quantization import quantize_dynamic

        logger.info(f"Quantizing model ({quantization_type})...")

        if quantization_type == "int8":
            quantize_dynamic(
                onnx_model_path,
                output_path,
                weight_type="int8",
            )
        else:
            logger.error(f"Unsupported quantization type: {quantization_type}")
            return None

        logger.info(f"✓ Quantization complete: {output_path}")
        return output_path

    except Exception as e:
        logger.error(f"✗ Quantization failed: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(
        description="Convert ONNX model to CoreML format"
    )
    parser.add_argument(
        "--onnx-model",
        required=True,
        help="Path to ONNX model file"
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path to output CoreML model"
    )
    parser.add_argument(
        "--quantize",
        choices=["int8", "float16"],
        default=None,
        help="Enable quantization"
    )
    parser.add_argument(
        "--minimum-ios-target",
        default="16.0",
        help="Minimum iOS version (default: 16.0)"
    )
    parser.add_argument(
        "--compute-units",
        choices=["auto", "cpu_and_gpu", "cpu_only"],
        default="auto",
        help="Compute units for inference"
    )
    parser.add_argument(
        "--inspect",
        action="store_true",
        help="Print model information and exit"
    )

    args = parser.parse_args()

    # Validate input
    onnx_path = Path(args.onnx_model)
    if not onnx_path.exists():
        logger.error(f"✗ ONNX model not found: {onnx_path}")
        exit(1)

    # Inspect model if requested
    if args.inspect:
        info = inspect_model(str(onnx_path))
        logger.info("Model Information:")
        logger.info(f"  Inputs: {info['inputs']}")
        logger.info(f"  Outputs: {info['outputs']}")
        logger.info(f"  Operators: {info['operator_count']}")
        return

    # Validate ONNX model
    if not validate_onnx_model(str(onnx_path)):
        exit(1)

    # Quantize if requested
    model_to_convert = str(onnx_path)
    if args.quantize:
        quantized_path = str(onnx_path.parent / f"{onnx_path.stem}_quantized.onnx")
        quantized_model = quantize_before_conversion(
            str(onnx_path),
            quantized_path,
            args.quantize
        )
        if quantized_model:
            model_to_convert = quantized_model

    # Convert to CoreML
    success = convert_onnx_to_coreml(
        model_to_convert,
        args.output,
        args.minimum_ios_target,
        args.compute_units,
    )

    exit(0 if success else 1)


if __name__ == "__main__":
    main()
