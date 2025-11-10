//
//  LiveKitService.swift
//  AI Voice Copilot
//

import Foundation
import AVFoundation
import LiveKit

protocol LiveKitServiceDelegate: AnyObject {
    func liveKitServiceDidConnect()
    func liveKitServiceDidDisconnect()
    func liveKitServiceDidFail(error: Error)
}

class LiveKitService {
    static let shared = LiveKitService()

    weak var delegate: LiveKitServiceDelegate?

    private var isConnected = false
    private var sessionId: String?
    private var room: Room?

    private init() {}

    func connect(sessionID: String, url: String, token: String) {
        self.sessionId = sessionID

        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                let room = Room()
                self.room = room

                room.add(delegate: self)

                try await room.connect(url: url, token: token)

                try await self.publishMicrophone(room: room)

                await self.subscribeToAssistantAudio(room: room)

                self.isConnected = true
                self.delegate?.liveKitServiceDidConnect()
            } catch {
                self.delegate?.liveKitServiceDidFail(error: error)
            }
        }
    }

    func disconnect() {
        Task { @MainActor [weak self] in
            guard let self = self, let room = self.room else { return }

            do {
                try await room.disconnect()
                self.room = nil
                self.isConnected = false
                self.sessionId = nil
                self.delegate?.liveKitServiceDidDisconnect()
            } catch {
                self.room = nil
                self.isConnected = false
                self.sessionId = nil
                self.delegate?.liveKitServiceDidDisconnect()
            }
        }
    }

    private func publishMicrophone(room: Room) async throws {
        let options = AudioCaptureOptions()
        let track = try LocalAudioTrack.createTrack(options: options)

        let publishOptions = TrackPublishOptions()
        publishOptions.source = .microphone

        try await room.localParticipant.publishAudioTrack(track: track, options: publishOptions)
    }

    private func subscribeToAssistantAudio(room: Room) async {
        for participant in room.remoteParticipants.values {
            for (_, publication) in participant.trackPublications {
                if publication.kind == .audio, !publication.isSubscribed {
                    try? await publication.subscribe()
                }
            }
        }

        room.add(delegate: self)
    }

    private func handleReconnection() {
        guard let room = room else { return }
        Task {
            await subscribeToAssistantAudio(room: room)
        }
    }
}

extension LiveKitService: RoomDelegate {
    func room(_ room: Room, didConnect isReconnect: Bool) {
        if isReconnect {
            handleReconnection()
        }
    }

    func room(_ room: Room, didDisconnect error: Error?) {
        if let error = error {
            delegate?.liveKitServiceDidFail(error: error)
        } else {
            delegate?.liveKitServiceDidDisconnect()
        }
    }

    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTo publication: RemoteTrackPublication, track: Track) {
        if publication.kind == .audio {
            // Audio track subscribed successfully
        }
    }
}
