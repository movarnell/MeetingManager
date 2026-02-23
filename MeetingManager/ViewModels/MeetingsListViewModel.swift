import Foundation
import Observation

@Observable
@MainActor
final class MeetingsListViewModel {
    var meetings: [Meeting] = []
    var searchText: String = ""
    var selectedMeetingId: UUID?

    var filteredMeetings: [Meeting] {
        if searchText.isEmpty { return meetings }
        return meetings.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var selectedMeeting: Meeting? {
        guard let id = selectedMeetingId else { return nil }
        return meetings.first { $0.id == id }
    }

    func loadMeetings() {
        meetings = (try? StorageService.shared.loadAllMeetings()) ?? []
    }

    func deleteMeeting(_ meeting: Meeting) {
        try? StorageService.shared.deleteMeeting(id: meeting.id)
        meetings.removeAll { $0.id == meeting.id }
        if selectedMeetingId == meeting.id {
            selectedMeetingId = meetings.first?.id
        }
    }

    func deleteMeetings(at offsets: IndexSet) {
        let toDelete = offsets.map { filteredMeetings[$0] }
        for meeting in toDelete {
            deleteMeeting(meeting)
        }
    }

    func addOrUpdateMeeting(_ meeting: Meeting) {
        if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[index] = meeting
        } else {
            meetings.insert(meeting, at: 0)
        }
        selectedMeetingId = meeting.id
    }

    func updateMeeting(_ meeting: Meeting) {
        try? StorageService.shared.saveMeeting(meeting)
        if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[index] = meeting
        }
    }
}
