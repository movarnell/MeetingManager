import Foundation

enum AppConstants {
    static let appName = "MeetingManager"
    static let whisperSampleRate: Double = 16000
    static let whisperChannels: UInt32 = 1

    enum Ollama {
        static let defaultBaseURL = URL(string: "http://localhost:11434")!
        static let chatEndpoint = "api/chat"
        static let tagsEndpoint = "api/tags"
        static let defaultTimeout: TimeInterval = 120
    }

    enum Recording {
        static let autoSaveInterval: TimeInterval = 30
        static let levelUpdateInterval: TimeInterval = 0.05
        static let timerUpdateInterval: TimeInterval = 0.1
    }

    enum UI {
        static let sidebarMinWidth: CGFloat = 220
        static let sidebarIdealWidth: CGFloat = 260
        static let windowMinWidth: CGFloat = 900
        static let windowMinHeight: CGFloat = 600
        static let levelMeterBarCount = 20
    }

    enum SystemPrompts {
        static let meetingNotes = """
        You are an expert meeting notes assistant. Analyze the following meeting \
        transcript and produce structured meeting notes in Markdown format.

        Your output MUST include these sections:

        ## Summary
        A 2-3 sentence overview of the meeting.

        ## Key Points
        - Bullet points of the most important topics discussed

        ## Action Items
        - [ ] Specific action items with owners if mentioned

        ## Decisions Made
        - Any decisions that were reached during the meeting

        ## Follow-ups
        - Items that need follow-up or further discussion

        Be concise but thorough. Use the participants' actual words when relevant. \
        If speakers can be distinguished, attribute statements to them.
        """
    }
}
