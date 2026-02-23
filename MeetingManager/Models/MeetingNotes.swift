import Foundation

enum NoteFormat: String, Codable, CaseIterable, Identifiable {
    case structured = "structured"
    case executive = "executive"
    case cornell = "cornell"
    case actionFocused = "actionFocused"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .structured: return "Structured Notes"
        case .executive: return "Executive Brief"
        case .cornell: return "Cornell Method"
        case .actionFocused: return "Action-Focused"
        }
    }

    var description: String {
        switch self {
        case .structured: return "Summary, key points, action items, and decisions"
        case .executive: return "High-level brief with bottom line up front"
        case .cornell: return "Questions, notes, and summary columns"
        case .actionFocused: return "Prioritized actions, owners, and deadlines"
        }
    }

    var icon: String {
        switch self {
        case .structured: return "list.bullet.rectangle"
        case .executive: return "briefcase"
        case .cornell: return "rectangle.split.2x1"
        case .actionFocused: return "checklist"
        }
    }

    var systemPrompt: String {
        switch self {
        case .structured:
            return """
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

        case .executive:
            return """
            You are an executive assistant creating a concise leadership brief from a meeting. \
            Write in Markdown format using a BLUF (Bottom Line Up Front) style.

            Your output MUST follow this exact structure:

            ## Bottom Line
            1-2 sentences: the single most important takeaway.

            ## Key Decisions
            - Decisions made, with brief context

            ## Risks & Blockers
            - Any risks, concerns, or blockers raised

            ## Next Steps
            - [ ] Critical next actions with owners

            ## Timeline
            - Key dates or deadlines mentioned

            Keep it extremely concise. A busy executive should be able to read this in under 2 minutes. \
            No filler. Every sentence must earn its place.
            """

        case .cornell:
            return """
            You are a note-taking assistant using the Cornell Method. Analyze the following meeting \
            transcript and produce notes in Markdown format organized in the Cornell style.

            Your output MUST follow this exact structure:

            ## Key Questions
            - Frame each major topic as a question that was addressed
            - Each question should capture a core theme of the discussion

            ## Notes
            For each question above, provide detailed notes:

            ### [Restate question 1 as a topic heading]
            - Detailed points discussed
            - Supporting details and examples mentioned
            - Any data or evidence referenced

            ### [Restate question 2 as a topic heading]
            - Detailed points discussed
            - Continue for each question...

            ## Summary
            A concise 3-5 sentence summary that answers the key questions and captures \
            the essence of the entire meeting. This should stand alone as a complete overview.

            Be thorough in the Notes section. The Questions should help organize and review the material.
            """

        case .actionFocused:
            return """
            You are a project management assistant focused on extracting actionable outcomes \
            from meetings. Write in Markdown format.

            Your output MUST follow this exact structure:

            ## Meeting Outcome
            One sentence describing what this meeting accomplished.

            ## Immediate Actions (Do This Week)
            - [ ] **[Owner]**: Action description — *Deadline if mentioned*
            - Prioritize by importance

            ## Upcoming Actions (Do This Month)
            - [ ] **[Owner]**: Action description — *Deadline if mentioned*

            ## Waiting On / Blocked
            - **[Person/Team]**: What is being waited on and why

            ## Commitments Made
            - **[Who]** committed to **[what]** by **[when]**

            ## Open Questions
            - Unresolved questions that still need answers
            - Who should answer them

            Focus ruthlessly on actions and accountability. Every item should have an owner \
            if one was mentioned. If no owner was stated, note it as **[Unassigned]**.
            """
        }
    }
}

struct MeetingNotes: Codable {
    var summary: String
    var keyPoints: [String]
    var actionItems: [String]
    var rawMarkdown: String
    var modelUsed: String
    var generatedAt: Date
    var format: NoteFormat

    init(
        summary: String = "",
        keyPoints: [String] = [],
        actionItems: [String] = [],
        rawMarkdown: String = "",
        modelUsed: String = "",
        generatedAt: Date = Date(),
        format: NoteFormat = .structured
    ) {
        self.summary = summary
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.rawMarkdown = rawMarkdown
        self.modelUsed = modelUsed
        self.generatedAt = generatedAt
        self.format = format
    }
}
