#!/usr/bin/env python3
"""
Download NVIDIA Parakeet TDT 0.6B v2 model from NGC or alternative sources.
"""

import argparse
import logging
from pathlib import Path
from typing import Optional

try:
    import requests
    from tqdm import tqdm
except ImportError:
    print("Error: Required packages not installed")
    print("Install with: pip install -r requirements.txt")
    exit(1)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# NGC API endpoints (example - replace with actual endpoints)
NGC_MODELS = {
    "parakeet_tdt_0.6b_v2": {
        "url": "https://api.ngc.nvidia.com/v2/models/nvidia_ngc/parakeet_tdt_0.6b_v2/versions/1/files/parakeet_tdt_0.6b_v2.onnx",
        "size": 630000000,  # ~600MB
        "checksum": None,
    }
}

# Alternative sources
ALT_SOURCES = {
    "huggingface": "https://huggingface.co/nvidia/parakeet_0.6b_v2/resolve/main/model.onnx",
}


def download_file(url: str, output_path: Path, chunk_size: int = 8192) -> bool:
    """Download file with progress bar."""
    try:
        logger.info(f"Downloading from: {url}")

        response = requests.get(url, stream=True, timeout=30)
        response.raise_for_status()

        total_size = int(response.headers.get("content-length", 0))
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, "wb") as f:
            with tqdm(total=total_size, unit="B", unit_scale=True) as pbar:
                for chunk in response.iter_content(chunk_size=chunk_size):
                    if chunk:
                        f.write(chunk)
                        pbar.update(len(chunk))

        logger.info(f"✓ Download complete: {output_path}")
        logger.info(f"  Size: {output_path.stat().st_size / 1e6:.2f} MB")
        return True

    except requests.RequestException as e:
        logger.error(f"✗ Download failed: {e}")
        return False
    except IOError as e:
        logger.error(f"✗ File write failed: {e}")
        return False


def verify_model(model_path: Path) -> bool:
    """Verify model file integrity."""
    try:
        import onnx

        logger.info(f"Verifying model: {model_path}")
        model = onnx.load(str(model_path))
        onnx.checker.check_model(model)

        logger.info("✓ Model verification passed")
        return True

    except Exception as e:
        logger.error(f"✗ Model verification failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Download NVIDIA Parakeet TDT model"
    )
    parser.add_argument(
        "--model",
        default="parakeet_tdt_0.6b_v2",
        choices=list(NGC_MODELS.keys()),
        help="Model to download"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("models"),
        help="Output directory"
    )
    parser.add_argument(
        "--source",
        choices=list(ALT_SOURCES.keys()) + ["ngc"],
        default="ngc",
        help="Download source"
    )
    parser.add_argument(
        "--skip-verify",
        action="store_true",
        help="Skip model verification"
    )

    args = parser.parse_args()

    # Determine download URL
    if args.source == "ngc":
        if args.model not in NGC_MODELS:
            logger.error(f"✗ Model not found in NGC: {args.model}")
            exit(1)
        url = NGC_MODELS[args.model]["url"]
    else:
        url = ALT_SOURCES.get(args.source)
        if not url:
            logger.error(f"✗ Invalid source: {args.source}")
            exit(1)

    # Set output path
    output_path = args.output / f"{args.model}.onnx"

    # Check if already exists
    if output_path.exists():
        logger.info(f"✓ Model already exists: {output_path}")
        if not args.skip_verify:
            verify_model(output_path)
        return

    # Download
    if not download_file(url, output_path):
        exit(1)

    # Verify
    if not args.skip_verify:
        if not verify_model(output_path):
            output_path.unlink()  # Delete invalid file
            exit(1)

    logger.info("✓ Model ready for conversion")
    logger.info(f"  Next step: python3 scripts/convert_model.py --onnx-model {output_path} --output models/parakeet.mlmodel")


if __name__ == "__main__":
    main()
