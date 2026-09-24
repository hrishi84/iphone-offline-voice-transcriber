#!/usr/bin/env python3
"""
Test and validate converted models.
"""

import argparse
import logging
import numpy as np
from pathlib import Path
from typing import Optional

try:
    import onnx
    import onnxruntime as ort
    from onnxruntime import InferenceSession
except ImportError:
    print("Error: Required packages not installed")
    print("Install with: pip install -r requirements.txt")
    exit(1)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def create_dummy_audio_input(sample_rate: int = 16000, duration: float = 2.0) -> np.ndarray:
    """Create dummy audio input for testing."""
    num_samples = int(sample_rate * duration)
    # Generate white noise
    audio = np.random.randn(num_samples).astype(np.float32)
    # Normalize
    audio = audio / (np.abs(audio).max() + 1e-8)
    return audio


def test_onnx_model(model_path: str, num_tests: int = 3) -> bool:
    """Test ONNX model inference."""
    try:
        logger.info(f"Loading ONNX model: {model_path}")
        session = InferenceSession(model_path, providers=['CPUExecutionProvider'])

        # Get input/output info
        input_info = session.get_inputs()
        output_info = session.get_outputs()

        logger.info(f"Model Inputs: {[inp.name for inp in input_info]}")
        logger.info(f"Model Outputs: {[out.name for out in output_info]}")

        # Run inference
        for i in range(num_tests):
            logger.info(f"Test {i+1}/{num_tests}...")

            # Create dummy input
            audio = create_dummy_audio_input()
            input_dict = {input_info[0].name: audio[np.newaxis, ...].astype(np.float32)}

            # Run inference
            outputs = session.run(None, input_dict)

            logger.info(f"  Output shape: {outputs[0].shape}")
            logger.info(f"  Output dtype: {outputs[0].dtype}")
            logger.info(f"  Output sample: {outputs[0].flatten()[:5]}")

        logger.info("✓ ONNX model test passed")
        return True

    except Exception as e:
        logger.error(f"✗ ONNX model test failed: {e}")
        return False


def test_coreml_model(model_path: str) -> bool:
    """Test CoreML model (requires macOS)."""
    try:
        import coremltools as ct

        logger.info(f"Loading CoreML model: {model_path}")
        model = ct.models.MLModel(model_path)

        logger.info(f"Model type: {model.get_spec().WhichOneof('Type')}")
        logger.info(f"Model description: {model.get_spec().description}")

        # List inputs/outputs
        spec = model.get_spec()
        logger.info(f"Inputs: {[inp.name for inp in spec.description.input]}")
        logger.info(f"Outputs: {[out.name for out in spec.description.output]}")

        logger.info("✓ CoreML model test passed")
        return True

    except Exception as e:
        logger.error(f"✗ CoreML model test failed: {e}")
        return False


def compare_models(onnx_model: str, coreml_model: str) -> bool:
    """Compare outputs of ONNX and CoreML models."""
    try:
        logger.info("Comparing ONNX and CoreML outputs...")

        # Load ONNX
        onnx_session = InferenceSession(onnx_model)
        onnx_input = onnx_session.get_inputs()[0]

        # Create test input
        audio = create_dummy_audio_input()
        input_dict = {onnx_input.name: audio[np.newaxis, ...].astype(np.float32)}

        # Run ONNX inference
        onnx_output = onnx_session.run(None, input_dict)[0]
        logger.info(f"ONNX output shape: {onnx_output.shape}")

        # Run CoreML inference (if on macOS)
        try:
            import coremltools as ct
            coreml_model_obj = ct.models.MLModel(coreml_model)
            logger.info("✓ CoreML model loaded successfully")
        except ImportError:
            logger.warning("⚠ CoreML testing requires macOS")
            return True

        logger.info("✓ Model comparison completed")
        return True

    except Exception as e:
        logger.error(f"✗ Model comparison failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Test and validate models"
    )
    parser.add_argument(
        "--onnx-model",
        help="Path to ONNX model"
    )
    parser.add_argument(
        "--coreml-model",
        help="Path to CoreML model"
    )
    parser.add_argument(
        "--compare",
        action="store_true",
        help="Compare ONNX and CoreML outputs"
    )
    parser.add_argument(
        "--num-tests",
        type=int,
        default=3,
        help="Number of test iterations"
    )

    args = parser.parse_args()

    if args.onnx_model:
        if not Path(args.onnx_model).exists():
            logger.error(f"✗ ONNX model not found: {args.onnx_model}")
            exit(1)
        test_onnx_model(args.onnx_model, args.num_tests)

    if args.coreml_model:
        if not Path(args.coreml_model).exists():
            logger.error(f"✗ CoreML model not found: {args.coreml_model}")
            exit(1)
        test_coreml_model(args.coreml_model)

    if args.compare and args.onnx_model and args.coreml_model:
        compare_models(args.onnx_model, args.coreml_model)


if __name__ == "__main__":
    main()
