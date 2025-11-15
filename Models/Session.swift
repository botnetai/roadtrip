//
//  Session.swift
//  AI Voice Copilot
//

import Foundation

struct Session: Identifiable, Codable {
    let id: String
    let userId: String
    let context: SessionContext
    let startedAt: Date
    var endedAt: Date?
    let loggingEnabledSnapshot: Bool
    var summaryStatus: SummaryStatus
    var summaryError: String?
    var summaryTitle: String?
    var summarySnippet: String?
    var summaryText: String?
    var durationMinutes: Int?

    enum SessionContext: String, Codable {
        case carplay
        case phone
    }

    enum SummaryStatus: String, Codable {
        case pending
        case ready
        case failed
    }
}

struct SessionSummary: Codable {
    let id: String
    let sessionId: String
    let title: String
    let summaryText: String
    let actionItems: [String]
    let tags: [String]
    let createdAt: Date
}

struct Turn: Identifiable, Codable {
    let id: String
    let sessionId: String
    let timestamp: Date
    let speaker: Speaker
    let text: String

    enum Speaker: String, Codable {
        case user
        case assistant
    }
}

struct SessionListItem: Identifiable, Codable {
    let id: String
    let title: String
    let summarySnippet: String
    let startedAt: Date
    let endedAt: Date?
    let context: Session.SessionContext?
    
    init(id: String, title: String, summarySnippet: String, startedAt: Date, endedAt: Date?, context: Session.SessionContext? = nil) {
        self.id = id
        self.title = title
        self.summarySnippet = summarySnippet
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.context = context
    }
}

struct StartSessionResponse: Codable {
    let sessionId: String
    let livekitUrl: String
    let livekitToken: String
    let roomName: String
}

extension Session {
    var displayTitle: String {
        if let title = summaryTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !title.isEmpty {
            return title
        }

        switch context {
        case .carplay:
            return "CarPlay Session"
        case .phone:
            return "Phone Session"
        }
    }

    var displaySnippet: String {
        if let snippet = summarySnippet?.trimmingCharacters(in: .whitespacesAndNewlines),
           !snippet.isEmpty {
            return snippet
        }

        switch summaryStatus {
        case .failed:
            return "Summary unavailable"
        case .pending:
            return "Processing summary..."
        case .ready:
            return context.rawValue.capitalized
        }
    }
}

extension SessionListItem {
    static func from(session: Session) -> SessionListItem {
        SessionListItem(
            id: session.id,
            title: session.displayTitle,
            summarySnippet: session.displaySnippet,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            context: session.context
        )
    }
}
