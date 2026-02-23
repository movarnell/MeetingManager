import Foundation

enum PreviewData {
    static let sampleMeeting: Meeting = {
        var meeting = Meeting(title: "Weekly Team Standup")
        meeting.duration = 1823
        meeting.tags = ["standup", "engineering"]
        meeting.transcript = sampleTranscript
        return meeting
    }()

    static let sampleTranscript = Transcript(
        segments: [
            TranscriptSegment(
                startTime: 0,
                endTime: 5.2,
                text: "Good morning everyone. Let's get started with our standup."
            ),
            TranscriptSegment(
                startTime: 5.2,
                endTime: 12.8,
                text: "Yesterday I worked on the authentication module and resolved the token refresh issue."
            ),
            TranscriptSegment(
                startTime: 12.8,
                endTime: 20.1,
                text: "Today I'm going to focus on the API integration tests and reviewing the pull request for the dashboard."
            ),
            TranscriptSegment(
                startTime: 20.1,
                endTime: 25.0,
                text: "No blockers for me. Sarah, do you want to go next?"
            ),
        ],
        fullText: "Good morning everyone. Let's get started with our standup. Yesterday I worked on the authentication module and resolved the token refresh issue. Today I'm going to focus on the API integration tests and reviewing the pull request for the dashboard. No blockers for me. Sarah, do you want to go next?"
    )

    static let sampleNotes = MeetingNotes(
        summary: "Weekly engineering standup covering progress on authentication, API testing, and dashboard features.",
        keyPoints: [
            "Authentication token refresh issue has been resolved",
            "API integration tests are the next priority",
            "Dashboard pull request needs review"
        ],
        actionItems: [
            "Complete API integration tests",
            "Review dashboard pull request",
            "Follow up on deployment timeline"
        ],
        rawMarkdown: """
        ## Summary
        Weekly engineering standup covering progress on authentication, API testing, and dashboard features.

        ## Key Points
        - Authentication token refresh issue has been resolved
        - API integration tests are the next priority
        - Dashboard pull request needs review

        ## Action Items
        - [ ] Complete API integration tests
        - [ ] Review dashboard pull request
        - [ ] Follow up on deployment timeline

        ## Decisions Made
        - Agreed to prioritize API tests before the next release

        ## Follow-ups
        - Check deployment timeline with DevOps
        """,
        modelUsed: "llama3.2",
        generatedAt: Date()
    )
}
