# Contributing Guidelines

Thank you for your interest in contributing to iPhone Offline Voice Transcriber!

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/iphone-offline-voice-transcriber.git`
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Commit with clear messages: `git commit -m "Add feature description"`
6. Push to your fork: `git push origin feature/your-feature`
7. Create a Pull Request

## Development Setup

```bash
# Clone and setup
git clone <repository>
cd iphone-offline-voice-transcriber

# Python environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Open iOS project
open ios/VoiceTranscriber.xcodeproj
```

## Code Style

### Swift

- Follow [Swift API Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use 4-space indentation
- Use meaningful variable and function names
- Add comments for complex logic

### Python

- Follow [PEP 8](https://pep8.org/)
- Use `black` for formatting
- Use `mypy` for type checking
- Use `flake8` for linting

```bash
black scripts/
flake8 scripts/
mypy scripts/
```

## Testing

### Swift Tests

```bash
cd ios
xcodebuild test -scheme VoiceTranscriber
```

### Python Tests

```bash
pytest tests/ -v --cov=scripts/
```

## Commit Messages

Use clear, descriptive commit messages:

```
Add feature: brief description

- Detailed explanation of what changed
- Why this change was necessary
- Any relevant issue numbers (fixes #123)
```

## Pull Request Process

1. **Update documentation** - Keep README and docs in sync
2. **Add tests** - Include tests for new features
3. **Verify locally** - Test on multiple devices/simulators
4. **Keep commits clean** - Use meaningful commit messages
5. **Request review** - Tag maintainers for review

## Areas for Contribution

### High Priority

- [ ] Complete CoreML model inference implementation
- [ ] Add streaming audio transcription
- [ ] Implement multi-language support
- [ ] Add comprehensive error handling

### Medium Priority

- [ ] Performance optimizations
- [ ] Additional audio preprocessing
- [ ] Expanded documentation
- [ ] Example apps and tutorials

### Low Priority

- [ ] UI improvements
- [ ] Additional language packs
- [ ] Integration with other services

## Reporting Bugs

Use GitHub Issues with:

1. **Clear title** - "Bug: description"
2. **Environment** - iOS version, device model, app version
3. **Steps to reproduce** - Exact steps that trigger the bug
4. **Expected vs actual** - What should happen vs what happens
5. **Logs** - Console output or debug information

## Feature Requests

Open an issue with:

1. **Title** - "Feature: description"
2. **Motivation** - Why this feature is needed
3. **Proposed solution** - How you'd implement it
4. **Alternatives** - Other approaches considered

## Documentation

- Keep README.md up to date
- Add docstrings to new functions
- Update CHANGELOG.md
- Add examples for new features

## Performance Considerations

- Profile code for bottlenecks
- Test on various iPhone models
- Monitor memory usage
- Optimize model inference

## Security

- Never hardcode credentials
- Validate all external inputs
- Follow privacy best practices
- Report security issues privately

## Questions?

- Open a Discussion on GitHub
- Create an Issue for clarification
- Check existing documentation

Thank you for contributing!
