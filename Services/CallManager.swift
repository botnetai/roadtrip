//
//  CallManager.swift
//  AI Voice Copilot
//

import Foundation
import CallKit
import AVFoundation
import UIKit

enum CallManagerError: LocalizedError {
    case timeout
    case audioSessionFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Call setup timed out. Please try again."
        case .audioSessionFailed(let error):
            return "Could not configure audio: \(error.localizedDescription)"
        }
    }
}

protocol CallManagerDelegate: AnyObject {
    func callManagerDidConnect()
    func callManagerDidDisconnect()
    func callManagerDidFail(error: Error)
}

class CallManager: NSObject {
    private static var _shared: CallManager?
    static var shared: CallManager {
        if _shared == nil {
            _shared = CallManager()
        }
        return _shared!
    }

    // Allow resetting shared instance for testing
    static func resetShared() {
        _shared = nil
    }

    weak var delegate: CallManagerDelegate?

    private let provider: CXProviderProtocol?
    private let callController: CXCallControllerProtocol?
    private var currentCallUUID: UUID?

    /// Tracks if a call request timed out - used to ignore late CallKit callbacks
    private var callRequestTimedOut = false

    /// iPad doesn't support CallKit, so we bypass it entirely on iPad
    /// Note: We check the actual hardware model, not userInterfaceIdiom, because
    /// iPhone-only apps running on iPad in compatibility mode report idiom as .phone
    private let isCallKitSupported: Bool

    // Dependency injection for testing
    init(provider: CXProviderProtocol? = nil, callController: CXCallControllerProtocol? = nil) {
        // CallKit is not supported on iPad - detect actual hardware model
        // UIDevice.current.model returns "iPad" for all iPad hardware regardless of compatibility mode
        let isActuallyiPad = UIDevice.current.model.contains("iPad")
        self.isCallKitSupported = !isActuallyiPad

        if let provider = provider, let callController = callController {
            // Test initialization
            self.provider = provider
            self.callController = callController
        } else if isCallKitSupported {
            // Production initialization for iPhone
            let configuration = CXProviderConfiguration()
            configuration.supportsVideo = false
            configuration.maximumCallsPerCallGroup = 1
            configuration.supportedHandleTypes = [.generic]
            configuration.iconTemplateImageData = nil

            self.provider = CXProvider(configuration: configuration)
            self.callController = CXCallController()
        } else {
            // iPad - no CallKit
            self.provider = nil
            self.callController = nil
        }

        super.init()

        self.provider?.setDelegate(self, queue: nil)
    }

    func startAssistantCall() {
        // Reset timeout flag for new call attempt
        callRequestTimedOut = false

        // On iPad, bypass CallKit entirely
        guard isCallKitSupported else {
            currentCallUUID = UUID()
            configureAudioSession()
            delegate?.callManagerDidConnect()
            return
        }

        let handle = CXHandle(type: .generic, value: "AI Assistant")
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        startCallAction.isVideo = false

        let transaction = CXTransaction(action: startCallAction)

        // Add timeout protection - CallKit can hang on some devices
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // Only timeout if we haven't received a response yet
            if self.currentCallUUID == nil {
                print("CallKit request timed out after 10 seconds")
                self.callRequestTimedOut = true
                self.delegate?.callManagerDidFail(error: CallManagerError.timeout)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeoutWorkItem)

        callController?.request(transaction) { [weak self] error in
            timeoutWorkItem.cancel()
            guard let self = self else { return }
            // Ignore late responses if we already timed out
            guard !self.callRequestTimedOut else {
                print("Ignoring late CallKit response after timeout")
                return
            }
            if let error = error {
                print("Error starting call: \(error)")
                // CallKit failed - fall back to non-CallKit mode automatically
                // This handles iPad, simulator, and any other CallKit issues
                print("Falling back to non-CallKit mode")
                self.currentCallUUID = UUID()
                self.configureAudioSession()
                self.delegate?.callManagerDidConnect()
            } else {
                self.currentCallUUID = startCallAction.callUUID
            }
        }
    }

    func reportCallConnected() {
        guard let uuid = currentCallUUID else { return }
        provider?.reportOutgoingCall(with: uuid, connectedAt: Date())
    }

    func endCurrentCall() {
        guard let callUUID = currentCallUUID else { return }

        // On iPad, bypass CallKit entirely
        guard isCallKitSupported else {
            deactivateAudioSession()
            currentCallUUID = nil
            delegate?.callManagerDidDisconnect()
            return
        }

        let endCallAction = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: endCallAction)

        callController?.request(transaction) { error in
            if let error = error {
                print("Error ending call: \(error)")
            }
        }
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [
                    .allowBluetoothHFP,
                    .allowBluetoothA2DP,
                    .allowAirPlay,
                    .defaultToSpeaker
                ]
            )
            try audioSession.setActive(true)

            // Speaker override can fail on some devices - don't fail the whole call
            // The call can still work through earpiece or other audio routes
            do {
                try audioSession.overrideOutputAudioPort(.speaker)
            } catch {
                print("Warning: Could not override to speaker (non-fatal): \(error)")
            }
        } catch {
            print("Error configuring audio session: \(error)")
            delegate?.callManagerDidFail(error: CallManagerError.audioSessionFailed(underlying: error))
        }
    }
    
    private func deactivateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
}

extension CallManager: CXProviderDelegate {
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        // Ignore late CallKit callbacks if we already timed out
        guard !callRequestTimedOut else {
            print("Ignoring late CXStartCallAction after timeout")
            action.fail()
            return
        }
        configureAudioSession()
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
        action.fulfill()
        delegate?.callManagerDidConnect()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        deactivateAudioSession()
        action.fulfill()
        currentCallUUID = nil
        delegate?.callManagerDidDisconnect()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
    }
    
    func providerDidReset(_ provider: CXProvider) {
        currentCallUUID = nil
    }
}
