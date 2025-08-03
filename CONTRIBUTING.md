# Contributing to Calendar MCP Server

Thank you for your interest in contributing to the Calendar MCP Server! This document provides guidelines and information for contributors.

## Getting Started

### Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Xcode Command Line Tools
- Access to macOS Calendar (EventKit permissions)

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/alexchambers/calendar-mcp.git
   cd calendar-mcp
   ```

2. **Build the project**
   ```bash
   swift build
   ```

3. **Run tests**
   ```bash
   swift test
   ```

4. **Build for release**
   ```bash
   swift build -c release
   ```

## Project Structure

```
├── Sources/CalendarMCP/
│   └── SimpleServer.swift          # Main MCP server implementation
├── Tests/CalendarMCPTests/
│   └── CalendarMCPTests.swift      # Test cases
├── Package.swift                   # Swift Package Manager configuration
├── README.md                       # Project documentation
├── build.sh                        # Convenience build script
└── .github/                        # GitHub templates and workflows
```

## Code Style and Standards

### Swift Style Guidelines

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use descriptive variable and function names
- Keep functions focused and small
- Add comments for complex logic
- Use `// MARK:` to organize code sections

### Code Organization

- All MCP server logic is in `SimpleServer.swift`
- Keep the single-file architecture for simplicity
- Group related functions together
- Use private functions for internal logic

### Error Handling

- Always check calendar access permissions
- Provide clear, user-friendly error messages
- Handle EventKit errors gracefully
- Log errors to stderr for debugging

## Contributing Process

### Before You Start

1. **Check existing issues** - Look for related issues or feature requests
2. **Create an issue** - For significant changes, create an issue first to discuss the approach
3. **Fork the repository** - Create your own fork to work in

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, readable code
   - Add comments for complex logic
   - Follow the existing code style

3. **Test your changes**
   ```bash
   swift test
   swift build -c release
   ```

4. **Update documentation** - Update README.md if you add new features

### Submitting Changes

1. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: brief description"
   ```

2. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request**
   - Use the provided PR template
   - Describe your changes clearly
   - Include testing instructions
   - Reference any related issues

## Types of Contributions

### Bug Fixes
- Fix calendar access issues
- Resolve date/time parsing problems
- Handle EventKit API edge cases

### New Features
- Additional calendar operations
- Enhanced search capabilities
- Better error reporting
- Performance improvements

### Documentation
- Improve README.md
- Add usage examples
- Update tool documentation
- Fix typos and clarity issues

### Testing
- Add test cases for new features
- Improve test coverage
- Add integration tests

## Testing Guidelines

### Manual Testing

Since this is a calendar integration:

1. **Test with different calendar types**
   - Local calendars
   - iCloud calendars
   - Exchange calendars
   - Subscribed calendars

2. **Test edge cases**
   - All-day events
   - Recurring events
   - Events with attachments
   - Events with attendees

3. **Test permissions**
   - First-time calendar access
   - Denied permissions
   - Revoked permissions

### Automated Testing

- Add unit tests for new functions
- Test error conditions
- Test date/time parsing logic
- Mock EventKit when possible

## EventKit Considerations

### Permissions
- Always check authorization status
- Request permissions gracefully
- Handle both macOS 14+ and earlier versions

### Calendar Types
- Not all calendars allow modifications
- Some calendars are read-only
- Handle subscription calendars appropriately

### Event Limitations
- Some recurring events can't be modified
- Attendee information may be read-only
- Alarms have specific requirements

## Debugging

### Logging
- Use `log()` function for debugging output
- Logs go to stderr and appear in Claude Desktop

### Common Issues
- **Calendar access denied**: Check System Settings > Privacy & Security > Calendars
- **Events not appearing**: Verify date range and calendar selection
- **Build failures**: Ensure Xcode Command Line Tools are installed

## Release Process

### Versioning
- Follow [Semantic Versioning](https://semver.org/)
- Update version in `Package.swift` and README.md
- Create git tags for releases

### Release Checklist
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Version numbers are bumped
- [ ] Release notes are prepared
- [ ] Binary builds successfully

## Getting Help

- **Issues**: Create a GitHub issue for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Email**: Contact the maintainer for sensitive issues

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers learn
- Maintain a welcoming environment

Thank you for contributing to making Calendar MCP Server better!