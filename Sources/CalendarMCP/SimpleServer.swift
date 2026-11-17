import Foundation
import EventKit

// Simple MCP server implementation
@main
struct CalendarMCPServer {
    static func main() async {
        let server = Server()
        await server.run()
    }
}

class Server {
    private let eventStore = EKEventStore()
    private var messageCodec = StdioMessageCodec()
    
    init() {
        setbuf(stdout, nil)
        setbuf(stderr, nil)
    }
    
    func run() async {
        while true {
            guard let data = try? FileHandle.standardInput.read(upToCount: 4096),
                  !data.isEmpty else {
                break
            }
            
            messageCodec.append(data)
            while let messageData = messageCodec.nextMessage() {
                await handleMessageData(messageData)
            }
        }
    }
    
    private func handleMessageData(_ data: Data) async {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            sendError(id: nil, code: -32700, message: "Parse error")
            return
        }
        
        guard let method = json["method"] as? String else { return }
        let id = json["id"]
        
        switch method {
        case "initialize":
            guard let id else {
                sendError(id: nil, code: -32600, message: "Invalid Request: initialize requires id")
                return
            }
            let response: [String: Any] = [
                "jsonrpc": "2.0",
                "id": id,
                "result": [
                    "protocolVersion": "2025-03-26",
                    "capabilities": [
                        "tools": [:]
                    ],
                    "serverInfo": [
                        "name": "calendar-mcp",
                        "version": "1.0.0"
                    ]
                ]
            ]
            sendJSON(response)
            
        case "notifications/initialized":
            // No response needed
            log("Client initialized")
            
        case "tools/list":
            guard let id else {
                sendError(id: nil, code: -32600, message: "Invalid Request: tools/list requires id")
                return
            }
            let response: [String: Any] = [
                "jsonrpc": "2.0",
                "id": id,
                "result": [
                    "tools": [
                        [
                            "name": "calendar_list_events",
                            "description": "List calendar events within a date range",
                            "inputSchema": [
                                "type": "object",
                                "properties": [
                                    "startDate": ["type": "string", "description": "Start date (YYYY-MM-DD)"],
                                    "endDate": ["type": "string", "description": "End date (YYYY-MM-DD)"]
                                ],
                                "required": ["startDate", "endDate"]
                            ]
                        ],
                        [
                            "name": "calendar_list_calendars",
                            "description": "List all available calendars",
                            "inputSchema": [
                                "type": "object",
                                "properties": [:],
                                "required": []
                            ]
                        ],
                        [
                            "name": "calendar_create_event",
                            "description": "Create a new calendar event",
                            "inputSchema": [
                                "type": "object",
                                "properties": [
                                    "title": ["type": "string", "description": "Event title"],
                                    "startDate": ["type": "string", "description": "Start date and time (YYYY-MM-DD HH:MM or YYYY-MM-DD)"],
                                    "endDate": ["type": "string", "description": "End date and time (YYYY-MM-DD HH:MM or YYYY-MM-DD)"],
                                    "calendarId": ["type": "string", "description": "Calendar identifier (optional, uses default if not specified)"],
                                    "location": ["type": "string", "description": "Event location (optional)"],
                                    "notes": ["type": "string", "description": "Event notes/description (optional)"],
                                    "allDay": ["type": "boolean", "description": "Whether this is an all-day event (optional, default: false)"],
                                    "recurrenceFrequency": ["type": "string", "description": "Recurrence frequency: daily, weekly, monthly, yearly (optional)"],
                                    "recurrenceInterval": ["type": "integer", "description": "Repeat every N intervals (optional, default: 1)"],
                                    "recurrenceEndDate": ["type": "string", "description": "End date for recurrence (YYYY-MM-DD, optional)"],
                                    "recurrenceCount": ["type": "integer", "description": "Maximum number of occurrences (optional)"],
                                    "recurrenceWeekdays": ["type": "array", "items": ["type": "string"], "description": "Days of week for weekly/monthly recurrence: sunday, monday, tuesday, wednesday, thursday, friday, saturday (optional)"],
                                    "recurrenceDaysOfMonth": ["type": "array", "items": ["type": "integer"], "description": "Days of month for monthly/yearly recurrence (1-31, optional)"],
                                    "recurrenceMonths": ["type": "array", "items": ["type": "integer"], "description": "Months for yearly recurrence (1-12, optional)"]
                                ],
                                "required": ["title", "startDate", "endDate"]
                            ]
                        ],
                        [
                            "name": "calendar_get_event",
                            "description": "Get detailed information about a specific event",
                            "inputSchema": [
                                "type": "object",
                                "properties": [
                                    "eventId": ["type": "string", "description": "Event identifier"]
                                ],
                                "required": ["eventId"]
                            ]
                        ],
                        [
                            "name": "calendar_update_event",
                            "description": "Update an existing calendar event",
                            "inputSchema": [
                                "type": "object",
                                "properties": [
                                    "eventId": ["type": "string", "description": "Event identifier"],
                                    "title": ["type": "string", "description": "Event title (optional)"],
                                    "startDate": ["type": "string", "description": "Start date and time (YYYY-MM-DD HH:MM or YYYY-MM-DD, optional)"],
                                    "endDate": ["type": "string", "description": "End date and time (YYYY-MM-DD HH:MM or YYYY-MM-DD, optional)"],
                                    "location": ["type": "string", "description": "Event location (optional)"],
                                    "notes": ["type": "string", "description": "Event notes/description (optional)"],
                                    "allDay": ["type": "boolean", "description": "Whether this is an all-day event (optional)"],
                                    "recurrenceFrequency": ["type": "string", "description": "Recurrence frequency: daily, weekly, monthly, yearly (optional)"],
                                    "recurrenceInterval": ["type": "integer", "description": "Repeat every N intervals (optional, default: 1)"],
                                    "recurrenceEndDate": ["type": "string", "description": "End date for recurrence (YYYY-MM-DD, optional)"],
                                    "recurrenceCount": ["type": "integer", "description": "Maximum number of occurrences (optional)"],
                                    "recurrenceWeekdays": ["type": "array", "items": ["type": "string"], "description": "Days of week for weekly/monthly recurrence: sunday, monday, tuesday, wednesday, thursday, friday, saturday (optional)"],
                                    "recurrenceDaysOfMonth": ["type": "array", "items": ["type": "integer"], "description": "Days of month for monthly/yearly recurrence (1-31, optional)"],
                                    "recurrenceMonths": ["type": "array", "items": ["type": "integer"], "description": "Months for yearly recurrence (1-12, optional)"]
                                ],
                                "required": ["eventId"]
                            ]
                        ],
                        [
                            "name": "calendar_delete_event",
                            "description": "Delete a calendar event",
                            "inputSchema": [
                                "type": "object",
                                "properties": [
                                    "eventId": ["type": "string", "description": "Event identifier"]
                                ],
                                "required": ["eventId"]
                            ]
                        ],
                        [
                            "name": "calendar_find_free_time",
                            "description": "Find free time slots across calendars within working hours. Ignores events marked 'free', declined/cancelled events, and all-day events unless marked busy. Birthday and subscribed calendars are skipped unless listed in calendarIds.",
                            "inputSchema": [
                                "type": "object",
                                "properties": [
                                    "startDate": ["type": "string", "description": "First day to search (YYYY-MM-DD)"],
                                    "endDate": ["type": "string", "description": "Last day to search (YYYY-MM-DD)"],
                                    "durationMinutes": ["type": "integer", "description": "Minimum slot length in minutes (default 60)"],
                                    "workdayStart": ["type": "string", "description": "Start of working hours HH:MM (default 09:00)"],
                                    "workdayEnd": ["type": "string", "description": "End of working hours HH:MM (default 18:00)"],
                                    "includeWeekends": ["type": "boolean", "description": "Include Saturdays and Sundays (default false)"],
                                    "bufferMinutes": ["type": "integer", "description": "Keep this many minutes free before and after existing events (default 0)"],
                                    "calendarIds": ["type": "array", "items": ["type": "string"], "description": "Only treat these calendars as busy (optional; default all except birthdays/subscriptions)"],
                                    "maxSlots": ["type": "integer", "description": "Maximum number of slots to return (default 30)"]
                                ],
                                "required": ["startDate", "endDate"]
                            ]
                        ],
                        [
                            "name": "calendar_search_events",
                            "description": "Search for events by title or content",
                            "inputSchema": [
                                "type": "object",
                                "properties": [
                                    "query": ["type": "string", "description": "Search query to match against event titles and notes"],
                                    "startDate": ["type": "string", "description": "Start date for search range (YYYY-MM-DD, optional)"],
                                    "endDate": ["type": "string", "description": "End date for search range (YYYY-MM-DD, optional)"],
                                    "calendarId": ["type": "string", "description": "Calendar identifier to search within (optional)"]
                                ],
                                "required": ["query"]
                            ]
                        ]
                    ]
                ]
            ]
            sendJSON(response)
            
        case "tools/call":
            guard let id else {
                sendError(id: nil, code: -32600, message: "Invalid Request: tools/call requires id")
                return
            }
            if let params = json["params"] as? [String: Any],
               let toolName = params["name"] as? String {
                
                let arguments = params["arguments"] as? [String: Any] ?? [:]
                let result: String
                
                switch toolName {
                case "calendar_list_events":
                    result = await callListEvents(arguments)
                case "calendar_list_calendars":
                    result = await callListCalendars(arguments)
                case "calendar_create_event":
                    result = await callCreateEvent(arguments)
                case "calendar_get_event":
                    result = await callGetEvent(arguments)
                case "calendar_update_event":
                    result = await callUpdateEvent(arguments)
                case "calendar_delete_event":
                    result = await callDeleteEvent(arguments)
                case "calendar_find_free_time":
                    result = await callFindFreeTime(arguments)
                case "calendar_search_events":
                    result = await callSearchEvents(arguments)
                default:
                    sendError(id: id, code: -32601, message: "Tool not found")
                    return
                }
                
                let response: [String: Any] = [
                    "jsonrpc": "2.0",
                    "id": id,
                    "result": [
                        "content": [["type": "text", "text": result]]
                    ]
                ]
                sendJSON(response)
            } else {
                sendError(id: id, code: -32602, message: "Invalid params")
            }
            
        default:
            sendError(id: id, code: -32601, message: "Method not found")
        }
    }
    
    private func callListEvents(_ arguments: [String: Any]) async -> String {
        // Check calendar access
        if let accessError = await checkCalendarAccess() {
            return accessError
        }
        
        guard let startDateStr = arguments["startDate"] as? String,
              let endDateStr = arguments["endDate"] as? String else {
            return "Missing required date parameters"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = formatter.date(from: startDateStr),
              let endDate = formatter.date(from: endDateStr) else {
            return "Invalid date format. Use YYYY-MM-DD"
        }
        
        // Fix edge case: when start and end dates are the same, extend end date to end of day
        let adjustedEndDate: Date
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            // Set end date to 23:59:59 of the same day to include all events
            adjustedEndDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        } else {
            adjustedEndDate = endDate
        }
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: adjustedEndDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        if events.isEmpty {
            return "No events found in the specified date range"
        }
        
        var result = "Found \(events.count) event(s):\n\n"
        for event in events.sorted(by: { $0.startDate < $1.startDate }) {
            result += "• \(event.title ?? "Untitled")\n"
            result += "  Start: \(formatDate(event.startDate))\n"
            result += "  End: \(formatDate(event.endDate))\n"
            if let location = event.location {
                result += "  Location: \(location)\n"
            }
            result += "\n"
        }
        
        return result
    }
    
    private func checkCalendarAccess() async -> String? {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        if !hasCalendarAccess(status) {
            if status == .notDetermined {
                let granted = await requestAccess()
                if !granted {
                    return "Calendar access denied. Please grant permission in System Settings."
                }
            } else {
                return "Calendar access denied. Please grant permission in System Settings."
            }
        }
        
        return nil
    }
    
    private func hasCalendarAccess(_ status: EKAuthorizationStatus) -> Bool {
        if #available(macOS 14.0, *) {
            return status == .fullAccess || status == .writeOnly || status == .authorized
        }
        
        return status == .authorized
    }
    
    private func callListCalendars(_ arguments: [String: Any]) async -> String {
        // Check calendar access
        if let accessError = await checkCalendarAccess() {
            return accessError
        }
        
        let calendars = eventStore.calendars(for: .event)
        
        if calendars.isEmpty {
            return "No calendars found"
        }
        
        var result = "Found \(calendars.count) calendar(s):\n\n"
        for calendar in calendars.sorted(by: { $0.title < $1.title }) {
            result += "• \(calendar.title)\n"
            result += "  ID: \(calendar.calendarIdentifier)\n"
            result += "  Type: \(calendarTypeDescription(calendar.type))\n"
            result += "  Source: \(calendar.source.title)\n"
            if let color = calendar.cgColor {
                result += "  Color: \(colorDescription(color))\n"
            }
            result += "  Allows Events: \(calendar.allowsContentModifications ? "Yes" : "No")\n"
            result += "\n"
        }
        
        return result
    }
    
    private func calendarTypeDescription(_ type: EKCalendarType) -> String {
        switch type {
        case .local:
            return "Local"
        case .calDAV:
            return "CalDAV"
        case .exchange:
            return "Exchange"
        case .subscription:
            return "Subscription"
        case .birthday:
            return "Birthday"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func colorDescription(_ cgColor: CGColor) -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "Unknown"
        }
        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        return "RGB(\(red), \(green), \(blue))"
    }
    
    private func createRecurrenceRule(from arguments: [String: Any]) -> EKRecurrenceRule? {
        guard let frequencyString = arguments["recurrenceFrequency"] as? String else {
            return nil
        }
        
        let frequency: EKRecurrenceFrequency
        switch frequencyString.lowercased() {
        case "daily":
            frequency = .daily
        case "weekly":
            frequency = .weekly
        case "monthly":
            frequency = .monthly
        case "yearly":
            frequency = .yearly
        default:
            return nil
        }
        
        let interval = arguments["recurrenceInterval"] as? Int ?? 1
        
        // Parse end condition
        let recurrenceEnd: EKRecurrenceEnd?
        if let endDateStr = arguments["recurrenceEndDate"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let endDate = formatter.date(from: endDateStr) {
                recurrenceEnd = EKRecurrenceEnd(end: endDate)
            } else {
                return nil // Invalid end date format
            }
        } else if let count = arguments["recurrenceCount"] as? Int {
            recurrenceEnd = EKRecurrenceEnd(occurrenceCount: count)
        } else {
            recurrenceEnd = nil // No end condition
        }
        
        // Parse days of the week
        var daysOfTheWeek: [EKRecurrenceDayOfWeek] = []
        if let weekdayStrings = arguments["recurrenceWeekdays"] as? [String] {
            for weekdayString in weekdayStrings {
                if let dayOfWeek = parseDayOfWeek(weekdayString) {
                    daysOfTheWeek.append(EKRecurrenceDayOfWeek(dayOfWeek))
                }
            }
        }
        
        // Parse days of the month
        var daysOfTheMonth: [NSNumber] = []
        if let days = arguments["recurrenceDaysOfMonth"] as? [Int] {
            daysOfTheMonth = days.compactMap { day in
                guard day >= 1 && day <= 31 else { return nil }
                return NSNumber(value: day)
            }
        }
        
        // Parse months of the year
        var monthsOfTheYear: [NSNumber] = []
        if let months = arguments["recurrenceMonths"] as? [Int] {
            monthsOfTheYear = months.compactMap { month in
                guard month >= 1 && month <= 12 else { return nil }
                return NSNumber(value: month)
            }
        }
        
        return EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: interval,
            daysOfTheWeek: daysOfTheWeek.isEmpty ? nil : daysOfTheWeek,
            daysOfTheMonth: daysOfTheMonth.isEmpty ? nil : daysOfTheMonth,
            monthsOfTheYear: monthsOfTheYear.isEmpty ? nil : monthsOfTheYear,
            weeksOfTheYear: nil, // Not supported in this implementation
            daysOfTheYear: nil,  // Not supported in this implementation
            setPositions: nil,   // Not supported in this implementation
            end: recurrenceEnd
        )
    }
    
    private func parseDayOfWeek(_ dayString: String) -> EKWeekday? {
        switch dayString.lowercased() {
        case "sunday":
            return .sunday
        case "monday":
            return .monday
        case "tuesday":
            return .tuesday
        case "wednesday":
            return .wednesday
        case "thursday":
            return .thursday
        case "friday":
            return .friday
        case "saturday":
            return .saturday
        default:
            return nil
        }
    }
    
    private func callCreateEvent(_ arguments: [String: Any]) async -> String {
        // Check calendar access
        if let accessError = await checkCalendarAccess() {
            return accessError
        }
        
        guard let title = arguments["title"] as? String,
              let startDateStr = arguments["startDate"] as? String,
              let endDateStr = arguments["endDate"] as? String else {
            return "Missing required parameters: title, startDate, endDate"
        }
        
        let allDay = arguments["allDay"] as? Bool ?? false
        let location = arguments["location"] as? String
        let notes = arguments["notes"] as? String
        let calendarId = arguments["calendarId"] as? String
        
        // Parse dates
        guard let startDate = parseDateTime(startDateStr, allDay: allDay, isEndDate: false),
              let endDate = parseDateTime(endDateStr, allDay: allDay, isEndDate: true) else {
            return "Invalid date format. Use YYYY-MM-DD for all-day events or YYYY-MM-DD HH:MM for timed events"
        }
        
        if startDate >= endDate {
            return "Start date must be before end date"
        }
        
        // Find calendar
        let targetCalendar: EKCalendar
        if let calendarId = calendarId {
            guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
                return "Calendar with ID '\(calendarId)' not found"
            }
            if !calendar.allowsContentModifications {
                return "Calendar '\(calendar.title)' does not allow modifications"
            }
            targetCalendar = calendar
        } else {
            // Use default calendar
            guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
                return "No default calendar available"
            }
            targetCalendar = defaultCalendar
        }
        
        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = allDay
        event.calendar = targetCalendar
        
        if let location = location {
            event.location = location
        }
        
        if let notes = notes {
            event.notes = notes
        }
        
        // Add recurrence rule if specified
        if let recurrenceRule = createRecurrenceRule(from: arguments) {
            event.recurrenceRules = [recurrenceRule]
        }
        
        // Save event
        do {
            try eventStore.save(event, span: .thisEvent)
            let recurrenceInfo = event.recurrenceRules?.isEmpty == false ? " (recurring)" : ""
            return "Event '\(title)' created successfully in calendar '\(targetCalendar.title)'\(recurrenceInfo)\nEvent ID: \(event.eventIdentifier ?? "unknown")"
        } catch {
            return "Failed to create event: \(error.localizedDescription)"
        }
    }
    
    private func parseDateTime(_ dateString: String, allDay: Bool, isEndDate: Bool = false) -> Date? {
        let dateFormatter = DateFormatter()
        
        if allDay {
            // For all-day events, use date only format
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: dateString)
        } else {
            // Try with time format first
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // Fall back to date only format; for timed events infer day boundary.
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let date = dateFormatter.date(from: dateString) else { return nil }
            if isEndDate {
                return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)
            }
            return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)
        }
    }
    
    private func callGetEvent(_ arguments: [String: Any]) async -> String {
        // Check calendar access
        if let accessError = await checkCalendarAccess() {
            return accessError
        }
        
        guard let eventId = arguments["eventId"] as? String else {
            return "Missing required parameter: eventId"
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            return "Event with ID '\(eventId)' not found"
        }
        
        var result = "Event Details:\n\n"
        result += "• Title: \(event.title ?? "Untitled")\n"
        result += "• Event ID: \(event.eventIdentifier ?? "unknown")\n"
        result += "• Start: \(formatDate(event.startDate))\n"
        result += "• End: \(formatDate(event.endDate))\n"
        result += "• All Day: \(event.isAllDay ? "Yes" : "No")\n"
        result += "• Calendar: \(event.calendar.title)\n"
        
        if let location = event.location, !location.isEmpty {
            result += "• Location: \(location)\n"
        }
        
        if let notes = event.notes, !notes.isEmpty {
            result += "• Notes: \(notes)\n"
        }
        
        if let url = event.url {
            result += "• URL: \(url.absoluteString)\n"
        }
        
        if event.hasRecurrenceRules, let rules = event.recurrenceRules {
            result += "• Recurring: Yes (\(rules.count) rule(s))\n"
            for rule in rules {
                result += "  - \(describeRecurrenceRule(rule))\n"
            }
        } else {
            result += "• Recurring: No\n"
        }
        
        if event.hasAlarms, let alarms = event.alarms {
            result += "• Alarms: \(alarms.count)\n"
            for alarm in alarms {
                if let date = alarm.absoluteDate {
                    result += "  - At \(formatDate(date))\n"
                } else {
                    let minutes = Int(alarm.relativeOffset / 60)
                    result += "  - \(minutes) minutes before\n"
                }
            }
        }
        
        if event.hasAttendees, let attendees = event.attendees {
            result += "• Attendees: \(attendees.count)\n"
            for attendee in attendees {
                let status = attendeeStatusDescription(attendee.participantStatus)
                result += "  - \(attendee.name ?? "Unknown") (\(status))\n"
            }
        }
        
        result += "• Created: \(event.creationDate.map(formatDate) ?? "Unknown")\n"
        result += "• Last Modified: \(event.lastModifiedDate.map(formatDate) ?? "Unknown")\n"
        
        return result
    }
    
    private func describeRecurrenceRule(_ rule: EKRecurrenceRule) -> String {
        let frequency: String
        switch rule.frequency {
        case .daily:
            frequency = "Daily"
        case .weekly:
            frequency = "Weekly"
        case .monthly:
            frequency = "Monthly"
        case .yearly:
            frequency = "Yearly"
        @unknown default:
            frequency = "Unknown"
        }
        
        let interval = rule.interval > 1 ? " every \(rule.interval)" : ""
        let end = rule.recurrenceEnd?.endDate.map { " until \(formatDate($0))" } ?? ""
        
        return "\(frequency)\(interval)\(end)"
    }
    
    private func attendeeStatusDescription(_ status: EKParticipantStatus) -> String {
        switch status {
        case .unknown:
            return "Unknown"
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        case .tentative:
            return "Tentative"
        case .delegated:
            return "Delegated"
        case .completed:
            return "Completed"
        case .inProcess:
            return "In Process"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func callUpdateEvent(_ arguments: [String: Any]) async -> String {
        // Check calendar access
        if let accessError = await checkCalendarAccess() {
            return accessError
        }
        
        guard let eventId = arguments["eventId"] as? String else {
            return "Missing required parameter: eventId"
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            return "Event with ID '\(eventId)' not found"
        }
        
        // Check if calendar allows modifications
        if !event.calendar.allowsContentModifications {
            return "Calendar '\(event.calendar.title)' does not allow modifications"
        }
        
        var hasChanges = false
        
        // Update title if provided
        if let title = arguments["title"] as? String {
            event.title = title
            hasChanges = true
        }
        
        // Update dates if provided
        if let startDateStr = arguments["startDate"] as? String {
            if let allDay = arguments["allDay"] as? Bool {
                event.isAllDay = allDay
                hasChanges = true
            }
            
            if let startDate = parseDateTime(startDateStr, allDay: event.isAllDay, isEndDate: false) {
                event.startDate = startDate
                hasChanges = true
            } else {
                return "Invalid start date format. Use YYYY-MM-DD for all-day events or YYYY-MM-DD HH:MM for timed events"
            }
        }
        
        if let endDateStr = arguments["endDate"] as? String {
            if let endDate = parseDateTime(endDateStr, allDay: event.isAllDay, isEndDate: true) {
                event.endDate = endDate
                hasChanges = true
            } else {
                return "Invalid end date format. Use YYYY-MM-DD for all-day events or YYYY-MM-DD HH:MM for timed events"
            }
        }
        
        // Validate date order
        if event.startDate >= event.endDate {
            return "Start date must be before end date"
        }
        
        // Update location if provided
        if let location = arguments["location"] as? String {
            event.location = location
            hasChanges = true
        }
        
        // Update notes if provided
        if let notes = arguments["notes"] as? String {
            event.notes = notes
            hasChanges = true
        }
        
        // Update all-day flag if provided (and dates weren't already updated)
        if arguments["startDate"] == nil, let allDay = arguments["allDay"] as? Bool {
            event.isAllDay = allDay
            hasChanges = true
        }
        
        // Update recurrence rule if provided
        if arguments["recurrenceFrequency"] != nil {
            if let recurrenceRule = createRecurrenceRule(from: arguments) {
                event.recurrenceRules = [recurrenceRule]
                hasChanges = true
            } else {
                return "Invalid recurrence parameters"
            }
        }
        
        if !hasChanges {
            return "No changes specified. Provide at least one field to update: title, startDate, endDate, location, notes, allDay, or recurrence parameters"
        }
        
        // Save changes
        do {
            try eventStore.save(event, span: .thisEvent)
            return "Event '\(event.title ?? "Untitled")' updated successfully"
        } catch {
            return "Failed to update event: \(error.localizedDescription)"
        }
    }
    
    private func callDeleteEvent(_ arguments: [String: Any]) async -> String {
        // Check calendar access
        if let accessError = await checkCalendarAccess() {
            return accessError
        }
        
        guard let eventId = arguments["eventId"] as? String else {
            return "Missing required parameter: eventId"
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            return "Event with ID '\(eventId)' not found"
        }
        
        // Check if calendar allows modifications
        if !event.calendar.allowsContentModifications {
            return "Calendar '\(event.calendar.title)' does not allow modifications"
        }
        
        let eventTitle = event.title ?? "Untitled"
        
        // Delete event
        do {
            try eventStore.remove(event, span: .thisEvent)
            return "Event '\(eventTitle)' deleted successfully"
        } catch {
            return "Failed to delete event: \(error.localizedDescription)"
        }
    }
    
    private func callSearchEvents(_ arguments: [String: Any]) async -> String {
        // Check calendar access
        if let accessError = await checkCalendarAccess() {
            return accessError
        }
        
        guard let query = arguments["query"] as? String else {
            return "Missing required parameter: query"
        }
        
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Search query cannot be empty"
        }
        
        // Parse optional date range
        let startDate: Date
        let endDate: Date
        
        if let startDateStr = arguments["startDate"] as? String,
           let endDateStr = arguments["endDate"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            guard let parsedStartDate = formatter.date(from: startDateStr),
                  let parsedEndDate = formatter.date(from: endDateStr) else {
                return "Invalid date format. Use YYYY-MM-DD"
            }
            
            startDate = parsedStartDate
            endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: parsedEndDate) ?? parsedEndDate
        } else {
            // Default to searching the past year and next year
            let calendar = Calendar.current
            startDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            endDate = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        }
        
        // Get calendars to search
        let calendarsToSearch: [EKCalendar]
        if let calendarId = arguments["calendarId"] as? String {
            guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
                return "Calendar with ID '\(calendarId)' not found"
            }
            calendarsToSearch = [calendar]
        } else {
            calendarsToSearch = eventStore.calendars(for: .event)
        }
        
        // Search for events
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendarsToSearch)
        let allEvents = eventStore.events(matching: predicate)
        
        // Filter events by search query
        let queryLower = query.lowercased()
        let matchingEvents = allEvents.filter { event in
            let title = event.title?.lowercased() ?? ""
            let notes = event.notes?.lowercased() ?? ""
            let location = event.location?.lowercased() ?? ""
            
            return title.contains(queryLower) || notes.contains(queryLower) || location.contains(queryLower)
        }
        
        if matchingEvents.isEmpty {
            let dateRange = arguments["startDate"] != nil ? "in specified date range" : "in the past and next year"
            return "No events found matching '\(query)' \(dateRange)"
        }
        
        var result = "Found \(matchingEvents.count) event(s) matching '\(query)':\n\n"
        for event in matchingEvents.sorted(by: { $0.startDate < $1.startDate }) {
            result += "• \(event.title ?? "Untitled")\n"
            result += "  ID: \(event.eventIdentifier ?? "unknown")\n"
            result += "  Start: \(formatDate(event.startDate))\n"
            result += "  End: \(formatDate(event.endDate))\n"
            result += "  Calendar: \(event.calendar.title)\n"
            
            if let location = event.location, !location.isEmpty {
                result += "  Location: \(location)\n"
            }
            
            // Show snippet of notes if they contain the search term
            if let notes = event.notes, !notes.isEmpty, notes.lowercased().contains(queryLower) {
                let snippet = String(notes.prefix(100))
                result += "  Notes: \(snippet)\(notes.count > 100 ? "..." : "")\n"
            }
            
            result += "\n"
        }
        
        return result
    }
    
    private func callFindFreeTime(_ arguments: [String: Any]) async -> String {
        if let accessError = await checkCalendarAccess() {
            return accessError
        }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        guard let startStr = arguments["startDate"] as? String, let endStr = arguments["endDate"] as? String,
              let startDay = dayFormatter.date(from: startStr), let endDay = dayFormatter.date(from: endStr) else {
            return "startDate and endDate are required (YYYY-MM-DD)"
        }
        let duration = TimeInterval(max(5, (arguments["durationMinutes"] as? Int) ?? 60) * 60)
        let buffer = TimeInterval(max(0, (arguments["bufferMinutes"] as? Int) ?? 0) * 60)
        let includeWeekends = arguments["includeWeekends"] as? Bool ?? false
        let maxSlots = max(1, (arguments["maxSlots"] as? Int) ?? 30)

        func hm(_ value: String?, _ fallback: (Int, Int)) -> (Int, Int) {
            guard let parts = value?.split(separator: ":").compactMap({ Int($0) }), parts.count == 2 else { return fallback }
            return (parts[0], parts[1])
        }
        let (startH, startM) = hm(arguments["workdayStart"] as? String, (9, 0))
        let (endH, endM) = hm(arguments["workdayEnd"] as? String, (18, 0))

        let calendars: [EKCalendar]
        if let ids = arguments["calendarIds"] as? [String], !ids.isEmpty {
            calendars = ids.compactMap { eventStore.calendar(withIdentifier: $0) }
            if calendars.isEmpty { return "None of the given calendarIds were found" }
        } else {
            calendars = eventStore.calendars(for: .event).filter { $0.type != .birthday && $0.type != .subscription }
        }

        let cal = Calendar.current
        guard let rangeEnd = cal.date(byAdding: .day, value: 1, to: endDay), rangeEnd > startDay else {
            return "endDate must be on or after startDate"
        }
        let events = eventStore.events(matching: eventStore.predicateForEvents(withStart: startDay, end: rangeEnd, calendars: calendars))

        // Busy intervals (with buffer), merged.
        var busy: [(Date, Date)] = events.compactMap { ev in
            guard let s = ev.startDate, let e = ev.endDate else { return nil }
            if ev.status == .canceled || ev.availability == .free { return nil }
            if ev.isAllDay && ev.availability != .busy { return nil }
            if let me = ev.attendees?.first(where: { $0.isCurrentUser }), me.participantStatus == .declined { return nil }
            return (s.addingTimeInterval(-buffer), e.addingTimeInterval(buffer))
        }.sorted { $0.0 < $1.0 }
        var merged: [(Date, Date)] = []
        for b in busy {
            if let last = merged.last, b.0 <= last.1 {
                merged[merged.count - 1].1 = max(last.1, b.1)
            } else {
                merged.append(b)
            }
        }
        busy = merged

        // Never suggest the past: round "now" up to the next quarter hour.
        let nowRounded: Date = {
            let now = Date()
            let minute = cal.component(.minute, from: now)
            let add = (15 - minute % 15) % 15
            return cal.date(bySetting: .second, value: 0, of: cal.date(byAdding: .minute, value: add == 0 ? 15 : add, to: now) ?? now) ?? now
        }()

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "EEE yyyy-MM-dd"

        var slots: [(Date, Date)] = []
        var day = startDay
        while day < rangeEnd && slots.count < maxSlots {
            defer { day = cal.date(byAdding: .day, value: 1, to: day) ?? rangeEnd }
            if !includeWeekends && cal.isDateInWeekend(day) { continue }
            guard let ws = cal.date(bySettingHour: startH, minute: startM, second: 0, of: day),
                  let we = cal.date(bySettingHour: endH, minute: endM, second: 0, of: day), we > ws else { continue }
            var cursor = max(ws, nowRounded)
            for b in busy where b.1 > cursor && b.0 < we {
                if b.0.timeIntervalSince(cursor) >= duration { slots.append((cursor, b.0)) }
                cursor = max(cursor, b.1)
            }
            if we.timeIntervalSince(cursor) >= duration { slots.append((cursor, we)) }
        }
        slots = Array(slots.prefix(maxSlots))

        if slots.isEmpty {
            return "No free slots of at least \(Int(duration / 60)) minutes between \(startStr) and \(endStr) within \(String(format: "%02d:%02d", startH, startM))–\(String(format: "%02d:%02d", endH, endM))."
        }
        var result = "Free slots of at least \(Int(duration / 60)) min (\(String(format: "%02d:%02d", startH, startM))–\(String(format: "%02d:%02d", endH, endM)), checked \(calendars.count) calendar(s)):\n"
        var lastDay = ""
        for (s, e) in slots {
            let d = dayFmt.string(from: s)
            if d != lastDay { result += "\n\(d)\n"; lastDay = d }
            let mins = Int(e.timeIntervalSince(s) / 60)
            let length = mins >= 60 ? "\(mins / 60)h\(mins % 60 > 0 ? " \(mins % 60)m" : "")" : "\(mins)m"
            result += "  • \(timeFmt.string(from: s))–\(timeFmt.string(from: e))  (\(length))\n"
        }
        return result
    }

    private func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            return (try? await eventStore.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func sendJSON(_ object: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: object) else { return }
        
        let header = "Content-Length: \(data.count)\r\n\r\n"
        guard let headerData = header.data(using: .utf8) else { return }
        
        FileHandle.standardOutput.write(headerData)
        FileHandle.standardOutput.write(data)
        fflush(stdout)
    }
    
    private func sendError(id: Any?, code: Int, message: String) {
        let response: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "error": ["code": code, "message": message]
        ]
        sendJSON(response)
    }
    
    private func log(_ message: String) {
        fputs("[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n", stderr)
        fflush(stderr)
    }
}

struct StdioMessageCodec {
    private var buffer = Data()
    
    mutating func append(_ data: Data) {
        buffer.append(data)
    }
    
    mutating func nextMessage() -> Data? {
        while true {
            trimLeadingLineBreaks()
            
            if let message = nextFramedMessage() {
                return message
            }
            if discardInvalidFramedHeaderIfPresent() {
                continue
            }
            if startsWithContentLengthHeader() {
                return nil
            }
            
            let remainingBytes = buffer.count
            if let message = nextLineMessage() {
                return message
            }
            if buffer.count < remainingBytes {
                continue
            }
            
            return nil
        }
    }
    
    private mutating func nextFramedMessage() -> Data? {
        guard startsWithContentLengthHeader(),
              let headerRange = buffer.range(of: Data("\r\n\r\n".utf8)),
              let headerString = String(data: buffer[..<headerRange.lowerBound], encoding: .utf8),
              let contentLength = parseContentLength(from: headerString) else {
            return nil
        }
        
        let bodyStart = headerRange.upperBound
        guard buffer.count >= bodyStart + contentLength else { return nil }
        
        let message = Data(buffer[bodyStart..<(bodyStart + contentLength)])
        buffer.removeSubrange(0..<(bodyStart + contentLength))
        return message
    }
    
    private mutating func nextLineMessage() -> Data? {
        guard let newlineIndex = buffer.firstIndex(of: 0x0A) else { return nil }
        
        var line = Data(buffer[..<newlineIndex])
        buffer.removeSubrange(0...newlineIndex)
        
        while line.last == 0x0D {
            line.removeLast()
        }
        
        let trimmed = String(data: line, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            return nil
        }
        
        return Data(trimmed.utf8)
    }
    
    private mutating func trimLeadingLineBreaks() {
        while let first = buffer.first, first == 0x0A || first == 0x0D {
            buffer.removeFirst()
        }
    }
    
    private func startsWithContentLengthHeader() -> Bool {
        guard buffer.count >= 15 else { return false }
        let prefix = Data(buffer.prefix(15))
        guard let prefixString = String(data: prefix, encoding: .utf8) else { return false }
        return prefixString.lowercased() == "content-length:"
    }
    
    private func parseContentLength(from header: String) -> Int? {
        for line in header.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            
            if parts[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length" {
                guard let value = Int(parts[1].trimmingCharacters(in: .whitespaces)),
                      value >= 0 else {
                    return nil
                }
                return value
            }
        }
        return nil
    }
    
    private mutating func discardInvalidFramedHeaderIfPresent() -> Bool {
        guard startsWithContentLengthHeader(),
              let headerRange = buffer.range(of: Data("\r\n\r\n".utf8)),
              let headerString = String(data: buffer[..<headerRange.lowerBound], encoding: .utf8),
              parseContentLength(from: headerString) == nil else {
            return false
        }
        
        buffer.removeSubrange(0..<headerRange.upperBound)
        return true
    }
}
