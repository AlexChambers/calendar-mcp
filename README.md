# Calendar MCP Server

A pure Swift implementation of a Model Context Protocol (MCP) server that provides native macOS Calendar (EventKit) access to AI assistants like Claude.

## Features

- **Pure Swift**: Single compiled binary with no dependencies
- **Native EventKit Integration**: Direct access to macOS Calendar
- **Simple & Lightweight**: ~400KB binary, instant startup
- **Zero Configuration**: Works out of the box

## Available Tools

### Event Management
- `calendar_list_events` - List events within a date range
- `calendar_create_event` - Create new calendar events
- `calendar_get_event` - Get detailed information about a specific event
- `calendar_update_event` - Update existing events  
- `calendar_delete_event` - Delete events
- `calendar_search_events` - Search for events by title, notes, or location

### Calendar Management
- `calendar_list_calendars` - List all available calendars with details

## Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Xcode Command Line Tools

## Building

```bash
# Clone the repository
git clone https://github.com/alexchambers/calendar-mcp.git
cd calendar-mcp

# Build the server
swift build -c release

# Or use the build script
./build.sh
```

## Installation for Claude Code

1. Build the server (see above)

2. Add to Claude Code using the MCP commands:

   ```bash
   # Remove existing version (if any)
   claude mcp remove calendar-mcp -s user
   
   # Add the server to user space (available in all projects)
   claude mcp add calendar-mcp -s user /path/to/calendar-mcp/.build/release/calendar-mcp
   ```

3. The server will be available in all your projects

### Additional MCP Commands

```bash
# List all MCP servers
claude mcp list

# List only user-space servers  
claude mcp list -s user

# Remove from user space
claude mcp remove calendar-mcp -s user

# Add to project-specific space (current project only)
claude mcp add calendar-mcp /path/to/calendar-mcp/.build/release/calendar-mcp
```

## Installation for Claude Desktop

1. Build the server (see above)

2. Add to Claude Desktop configuration:
   
   Open `~/Library/Application Support/Claude/claude_desktop_config.json` and add:

   ```json
   {
       "mcpServers": {
           "calendar-mcp": {
               "type": "stdio",
               "command": "/path/to/calendar-mcp/.build/release/calendar-mcp"
           }
       }
   }
   ```

3. Restart Claude Desktop

4. On first use, macOS will prompt for calendar access. Grant permission for the server to work.

## Usage Examples

Once installed, you can ask Claude to:

### Viewing Events
- "Show me my calendar events for next week"
- "List my events from December 1 to December 15"
- "What's on my calendar today?"
- "Get details for event ID ABC123"

### Creating Events
- "Create a meeting titled 'Team Standup' tomorrow from 9:00 to 9:30"
- "Schedule an all-day event called 'Conference' on March 15th"
- "Add a doctor's appointment on Friday at 2pm with location 'Medical Center'"
- "Create a daily recurring meeting at 9am for the next 10 days"
- "Schedule a weekly team meeting every Monday at 2pm"
- "Set up a monthly bill reminder on the 1st of each month"

### Managing Events
- "Update the meeting title to 'Daily Standup'"
- "Move my 3pm meeting to 4pm"
- "Delete the event with ID XYZ789"
- "Change the location of my dentist appointment to 'Downtown Clinic'"

### Searching Events
- "Find all events with 'meeting' in the title"
- "Search for events containing 'project review' in the next month"
- "Show me all events at 'Conference Room A'"

### Calendar Management
- "List all my calendars"
- "Show me which calendars I can create events in"

### Recurring Events
- "Create a daily standup meeting for 30 days"
- "Schedule a weekly team meeting every Friday at 3pm"
- "Set up a monthly billing reminder on the 15th"
- "Create a yearly birthday reminder"
- "Schedule a meeting every Tuesday and Thursday at 10am"
- "Set up a quarterly review meeting (every 3 months)"

## Tool Reference

### calendar_list_events
List calendar events within a date range.
- **Parameters**: `startDate` (YYYY-MM-DD), `endDate` (YYYY-MM-DD)
- **Returns**: List of events with title, start/end times, and location

### calendar_create_event
Create a new calendar event.
- **Parameters**: 
  - `title` (required) - Event title
  - `startDate` (required) - Start date/time (YYYY-MM-DD or YYYY-MM-DD HH:MM)
  - `endDate` (required) - End date/time (YYYY-MM-DD or YYYY-MM-DD HH:MM)
  - `calendarId` (optional) - Target calendar ID
  - `location` (optional) - Event location
  - `notes` (optional) - Event description
  - `allDay` (optional) - Boolean for all-day events
  - **Recurrence Parameters (optional)**:
    - `recurrenceFrequency` - daily, weekly, monthly, yearly
    - `recurrenceInterval` - Repeat every N intervals (default: 1)
    - `recurrenceEndDate` - End date for recurrence (YYYY-MM-DD)
    - `recurrenceCount` - Maximum number of occurrences
    - `recurrenceWeekdays` - Array of weekdays (sunday, monday, etc.)
    - `recurrenceDaysOfMonth` - Array of days (1-31) for monthly/yearly
    - `recurrenceMonths` - Array of months (1-12) for yearly
- **Returns**: Success message with event ID

### calendar_get_event
Get detailed information about a specific event.
- **Parameters**: `eventId` (required) - Event identifier
- **Returns**: Complete event details including attendees, alarms, recurrence

### calendar_update_event
Update an existing calendar event.
- **Parameters**: 
  - `eventId` (required) - Event identifier
  - `title`, `startDate`, `endDate`, `location`, `notes`, `allDay` (optional)
  - **Recurrence Parameters (optional)**:
    - `recurrenceFrequency` - daily, weekly, monthly, yearly
    - `recurrenceInterval` - Repeat every N intervals (default: 1)
    - `recurrenceEndDate` - End date for recurrence (YYYY-MM-DD)
    - `recurrenceCount` - Maximum number of occurrences
    - `recurrenceWeekdays` - Array of weekdays (sunday, monday, etc.)
    - `recurrenceDaysOfMonth` - Array of days (1-31) for monthly/yearly
    - `recurrenceMonths` - Array of months (1-12) for yearly
- **Returns**: Success confirmation

### calendar_delete_event
Delete a calendar event.
- **Parameters**: `eventId` (required) - Event identifier
- **Returns**: Success confirmation

### calendar_search_events
Search for events by title, notes, or location.
- **Parameters**: 
  - `query` (required) - Search text
  - `startDate`, `endDate` (optional) - Date range to search
  - `calendarId` (optional) - Specific calendar to search
- **Returns**: List of matching events

### calendar_list_calendars
List all available calendars.
- **Parameters**: None
- **Returns**: Calendar details including ID, type, source, and permissions

## Security

The server requests calendar access through macOS's standard permission system. You'll be prompted to grant access on first use. The server only accesses calendar data when explicitly requested through Claude.

## Architecture

The entire server is implemented in a single Swift file (`SimpleServer.swift`) that:
- Handles JSON-RPC communication over stdio
- Integrates directly with EventKit for calendar access
- Implements the MCP protocol without external dependencies

## Technical Details

- **Transport**: stdio (standard input/output)
- **Protocol**: MCP over JSON-RPC 2.0
- **Calendar Access**: EventKit framework
- **Concurrency**: Swift async/await

## Troubleshooting

### Calendar Access Denied
If you see "Calendar access denied", go to System Settings > Privacy & Security > Calendars and ensure the terminal or Claude has access.

### Server Not Starting
Check that the path in your Claude Desktop config is correct and the binary is executable:
```bash
chmod +x /path/to/calendar-mcp/.build/release/calendar-mcp
```

### Debugging
The server logs to stderr. You can see logs in Claude Desktop's MCP server output.

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Why Pure Swift?

This project demonstrates the simplicity of building MCP servers in Swift:

- **No Dependencies**: Just Swift and macOS frameworks
- **Type Safety**: Swift's type system ensures protocol compliance
- **Performance**: Compiled binary with native performance
- **Direct Integration**: No bridges or subprocesses needed
- **Single Language**: Entire stack in Swift

Perfect for macOS developers who want to extend AI assistants with native capabilities!