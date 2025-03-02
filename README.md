# WaveSynk iOS App

A surf forecasting and alert system that helps surfers catch the perfect wave.

## Version
Current Version: 1.0.0

## Requirements
- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

## Setup Instructions

1. Clone the repository
```bash
git clone [repository-url]
cd WaveSynkIOS
```

2. Create Configuration Files
- Copy `Configuration/Secrets.swift.example` to `Configuration/Secrets.swift`
- Add your API keys to `Secrets.swift`

3. Install Dependencies
- No external dependencies required for MVP

4. Build and Run
- Open `WaveSynk.xcodeproj`
- Select your target device
- Build and run (⌘R)

## Development Workflow

1. Branch Strategy
- `main`: Production-ready code
- `development`: Main development branch
- `feature/*`: New features
- `bugfix/*`: Bug fixes
- `release/*`: Release preparation

2. Commit Guidelines
- Use descriptive commit messages
- Reference issue numbers when applicable
- Keep commits focused and atomic

3. Pull Request Process
- Create PR against `development` branch
- Ensure tests pass
- Request code review
- Squash and merge when approved

## Architecture

- SwiftUI for UI
- SwiftData for persistence
- MVVM architecture
- Feature-based folder structure

## Testing

Run tests using:
```bash
xcodebuild test -scheme WaveSynk -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Security

- API keys stored in `Secrets.swift` (gitignored)
- Environment-based configuration
- Secure storage for user data
- HTTPS for all network requests

## Contact

For questions or support, contact:
- Development Team: dev@wavesynk.com
- Support: support@wavesynk.com

## License

Copyright © 2024 WaveSynk. All rights reserved.
