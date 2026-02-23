import Foundation
import Observation

@Observable
@MainActor
final class RecordingViewModel {
    let recordingService = AudioRecordingService()
    private(set) var currentMeetingId: UUID?
    var meetingTitle: String = ""
    var errorMessage: String?

    var state: RecordingState { recordingService.state }
    var duration: TimeInterval { recordingService.duration }
    var micLevel: Float { recordingService.micLevel }
    var systemLevel: Float { recordingService.systemLevel }

    var micEnabled: Bool {
        get { recordingService.micEnabled }
        set { recordingService.micEnabled = newValue }
    }

    var systemAudioEnabled: Bool {
        get { recordingService.systemAudioEnabled }
        set { recordingService.systemAudioEnabled = newValue }
    }

    var atLeastOneSourceEnabled: Bool {
        micEnabled || systemAudioEnabled
    }

    func startRecording() async throws -> UUID {
        guard atLeastOneSourceEnabled else {
            throw AudioRecordingService.RecordingError.noAudioSourceEnabled
        }

        errorMessage = nil
        let meeting = Meeting(title: meetingTitle.isEmpty ? "Meeting \(DateFormatters.meetingDate.string(from: Date()))" : meetingTitle)
        currentMeetingId = meeting.id

        // Pre-save the meeting
        try StorageService.shared.saveMeeting(meeting)

        do {
            try await recordingService.startRecording(meetingId: meeting.id)
        } catch {
            errorMessage = error.localizedDescription
            currentMeetingId = nil
            throw error
        }

        return meeting.id
    }

    func stopRecording() async -> Meeting? {
        guard let meetingId = currentMeetingId else { return nil }

        let finalDuration = await recordingService.stopRecording()

        do {
            var meeting = try StorageService.shared.loadMeeting(id: meetingId)
            meeting.duration = finalDuration
            meeting.isRecording = false

            if micEnabled {
                let micURL = StorageService.shared.audioFileURL(for: meetingId, type: .microphone)
                if FileManager.default.fileExists(atPath: micURL.path) {
                    meeting.micAudioFileURL = micURL
                }
            }
            if systemAudioEnabled {
                let sysURL = StorageService.shared.audioFileURL(for: meetingId, type: .systemAudio)
                if FileManager.default.fileExists(atPath: sysURL.path) {
                    meeting.systemAudioFileURL = sysURL
                }
            }

            // Create mixed audio for transcription if both sources were enabled
            if meeting.micAudioFileURL != nil && meeting.systemAudioFileURL != nil {
                let mixedURL = StorageService.shared.audioFileURL(for: meetingId, type: .mixed)
                try? await AudioMixerService.mixAudioFiles(
                    micFileURL: meeting.micAudioFileURL,
                    systemFileURL: meeting.systemAudioFileURL,
                    outputURL: mixedURL
                )
                if FileManager.default.fileExists(atPath: mixedURL.path) {
                    meeting.audioFileURL = mixedURL
                }
            } else {
                // Single source - use whichever is available
                meeting.audioFileURL = meeting.micAudioFileURL ?? meeting.systemAudioFileURL
            }

            try StorageService.shared.saveMeeting(meeting)
            currentMeetingId = nil
            meetingTitle = ""
            return meeting
        } catch {
            errorMessage = error.localizedDescription
            currentMeetingId = nil
            return nil
        }
    }

    func addBookmark() {
        guard let meetingId = currentMeetingId, state == .recording else { return }
        do {
            var meeting = try StorageService.shared.loadMeeting(id: meetingId)
            let bookmark = MeetingBookmark(timestamp: duration)
            meeting.bookmarks.append(bookmark)
            try StorageService.shared.saveMeeting(meeting)
        } catch {
            // Non-critical, silently fail
        }
    }
}
