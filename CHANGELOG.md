# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial public release preparation
- Comprehensive GitHub repository structure
- Contributing guidelines and issue templates

## [1.0.0] - 2025-08-03

### Added
- Complete MCP server implementation for macOS Calendar access
- Seven comprehensive calendar tools:
  - `calendar_list_events` - List events within a date range
  - `calendar_list_calendars` - List all available calendars
  - `calendar_create_event` - Create new calendar events
  - `calendar_get_event` - Get detailed event information
  - `calendar_update_event` - Update existing events
  - `calendar_delete_event` - Delete events
  - `calendar_search_events` - Search events by content
- Full recurring event support with multiple recurrence patterns
- Comprehensive error handling and permission checking
- Pure Swift implementation with no external dependencies
- EventKit integration for native macOS calendar access
- Support for all-day and timed events
- Location, notes, and attendee information handling
- Alarm and recurrence rule descriptions
- Multiple date format parsing (YYYY-MM-DD and YYYY-MM-DD HH:MM)

### Technical Details
- Swift 5.9+ requirement
- macOS 13.0+ requirement
- Single compiled binary (~400KB)
- JSON-RPC 2.0 over stdout/stdin transport
- Async/await concurrency model
- Comprehensive calendar permission handling

### Documentation
- Complete README with usage examples
- Tool reference documentation
- Installation instructions for Claude Code and Claude Desktop
- Troubleshooting guide
- Architecture overview

[Unreleased]: https://github.com/alexchambers/calendar-mcp/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/alexchambers/calendar-mcp/releases/tag/v1.0.0