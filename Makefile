.PHONY: help setup download convert test build run clean docs

help:
	@echo "iPhone Offline Voice Transcriber - Available Commands"
	@echo ""
	@echo "setup          - Setup development environment"
	@echo "download       - Download model from NGC"
	@echo "convert        - Convert ONNX model to CoreML"
	@echo "test           - Run tests"
	@echo "build          - Build iOS app"
	@echo "run            - Run app on simulator"
	@echo "clean          - Clean build artifacts"
	@echo "docs           - Build documentation"
	@echo "format         - Format code (Python + Swift)"
	@echo "lint           - Run linters"

setup:
	python3 -m venv venv
	. venv/bin/activate && pip install -r requirements.txt
	@echo "✓ Setup complete. Run 'source venv/bin/activate' to activate virtual env"

download:
	python3 scripts/download_model.py

convert:
	python3 scripts/convert_model.py \
		--onnx-model models/parakeet_tdt_0.6b_v2.onnx \
		--output models/parakeet_tdt_0.6b_v2.mlmodel \
		--quantize int8

test:
	pytest tests/ -v --cov=scripts/

build:
	xcodebuild build -scheme VoiceTranscriber -configuration Debug

run:
	xcodebuild -scheme VoiceTranscriber \
		-configuration Debug \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=iPhone 14' \
		-verbose

clean:
	rm -rf build/
	rm -rf ios/VoiceTranscriber.xcodeproj/xcuserdata/
	rm -rf models/*.onnx models/*.mlmodel
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true

docs:
	@echo "Documentation files:"
	@echo "- README.md"
	@echo "- docs/ARCHITECTURE.md"
	@echo "- docs/MODEL_CONVERSION.md"
	@echo "- docs/INSTALLATION.md"
	@echo "- docs/CONTRIBUTING.md"

format:
	black scripts/ --line-length=100
	isort scripts/
	@echo "✓ Python formatting complete"

lint:
	flake8 scripts/ --max-line-length=100
	mypy scripts/ --ignore-missing-imports
	@echo "✓ Python linting complete"

full-pipeline: setup download convert test build
	@echo "✓ Full pipeline complete!"
