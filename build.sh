#!/bin/bash

# Build the calendar-mcp server
echo "Building Calendar MCP Server..."
swift build -c release

# Create a convenient link
if [ -f ".build/release/calendar-mcp" ]; then
    echo "Build successful!"
    echo ""
    echo "To install for Claude Desktop:"
    echo "1. Copy the following configuration to your Claude Desktop config:"
    echo ""
    echo '{
    "mcpServers": {
        "calendar-mcp": {
            "type": "stdio",
            "command": "'$(pwd)'/.build/release/calendar-mcp"
        }
    }
}'
    echo ""
    echo "2. Add it to: ~/Library/Application Support/Claude/claude_desktop_config.json"
else
    echo "Build failed!"
    exit 1
fi