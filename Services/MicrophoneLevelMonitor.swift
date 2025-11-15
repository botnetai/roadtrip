//
//  MicrophoneLevelMonitor.swift
//  AI Voice Copilot
//

import Foundation
import AVFoundation
import AVFAudio
import Combine
import CoreGraphics

@MainActor
final class MicrophoneLevelMonitor: ObservableObject {
    static let shared = MicrophoneLevelMonitor()

    @Published private(set) var level: CGFloat = 0
    @Published private(set) var isMonitoring = false
    private let smoothingFactor: CGFloat = 0.25

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var fallbackTimer: Timer?

    private init() {}

    func startMonitoring() {
        guard !isMonitoring else { return }
        handlePermission()
    }

    func stopMonitoring() {
        audioRecorder?.stop()
        audioRecorder = nil

        levelTimer?.invalidate()
        levelTimer = nil

        fallbackTimer?.invalidate()
        fallbackTimer = nil

        level = 0
        isMonitoring = false
    }

    private func handlePermission() {
        let session = AVAudioSession.sharedInstance()
        let audioApplication = AVAudioApplication.shared

        switch audioApplication.recordPermission {
        case .granted:
            startRecorder(with: session)
        case .denied:
            startFallbackAnimation()
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if granted {
                        self.startRecorder(with: session)
                    } else {
                        self.startFallbackAnimation()
                    }
                }
            }
        @unknown default:
            startFallbackAnimation()
        }
    }

    private func startRecorder(with session: AVAudioSession) {
        do {
            if AVAudioApplication.shared.recordPermission != .granted {
                startFallbackAnimation()
                return
            }

            let url = URL(fileURLWithPath: "/dev/null")
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()
            recorder.record()

            audioRecorder = recorder
            startLevelUpdates()
        } catch {
            print("⚠️ Failed to start microphone monitor: \(error)")
            startFallbackAnimation()
        }
    }

    private func startLevelUpdates() {
        isMonitoring = true

        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(handleLevelTimer(_:)), userInfo: nil, repeats: true)
    }

    private func normalizedPower(from decibels: Float) -> CGFloat {
        let minDb: Float = -80
        if decibels <= minDb {
            return 0
        }

        let clamped = min(0, decibels)
        let range = -minDb
        let normalized = (clamped + abs(minDb)) / range
        return CGFloat(max(0, min(1, normalized)))
    }

    private func startFallbackAnimation() {
        isMonitoring = true
        fallbackTimer?.invalidate()
        fallbackTimer = Timer.scheduledTimer(timeInterval: 0.12, target: self, selector: #selector(handleFallbackTimer(_:)), userInfo: nil, repeats: true)
    }

    @objc private func handleLevelTimer(_ timer: Timer) {
        audioRecorder?.updateMeters()
        if let power = audioRecorder?.averagePower(forChannel: 0) {
            let normalized = normalizedPower(from: power)
            level = normalized * smoothingFactor + level * (1 - smoothingFactor)
        } else {
            level = 0
        }
    }

    @objc private func handleFallbackTimer(_ timer: Timer) {
        let base = CGFloat.random(in: 0.15...0.35)
        let variance = CGFloat.random(in: 0...0.2)
        level = min(1, base + variance)
    }
}
