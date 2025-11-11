//
//  UserSettings.swift
//  Shaw
//

import Foundation
import Observation

/// AI Model options supported by LiveKit Inference
/// Models use the provider/model format as required by LiveKit agents
/// See: https://docs.livekit.io/agents/models/#inference
enum AIModel: String, CaseIterable, Codable {
    // OpenAI models available through LiveKit Inference
    case gpt41 = "openai/gpt-4.1"
    case gpt41Mini = "openai/gpt-4.1-mini"
    case gpt41Nano = "openai/gpt-4.1-nano"
    
    // Google models available through LiveKit Inference
    case gemini25Pro = "google/gemini-2.5-pro"
    case gemini25FlashLite = "google/gemini-2.5-flash-lite"
    
    var displayName: String {
        switch self {
        case .gpt41:
            return "GPT-4.1"
        case .gpt41Mini:
            return "GPT-4.1 Mini"
        case .gpt41Nano:
            return "GPT-4.1 Nano"
        case .gemini25Pro:
            return "Gemini 2.5 Pro"
        case .gemini25FlashLite:
            return "Gemini 2.5 Flash Lite"
        }
    }
    
    var description: String {
        switch self {
        case .gpt41:
            return "Full GPT-4.1 model with enhanced capabilities"
        case .gpt41Mini:
            return "Balanced GPT-4.1 model optimized for speed and cost"
        case .gpt41Nano:
            return "Lightweight GPT-4.1 model for fast responses"
        case .gemini25Pro:
            return "Google's most capable Gemini model"
        case .gemini25FlashLite:
            return "Fast and efficient Gemini model"
        }
    }
}

/// TTS Provider options supported by LiveKit Inference
/// See: https://docs.livekit.io/agents/models/tts/#inference
enum TTSProvider: String, CaseIterable, Codable {
    case cartesia = "cartesia"
    case elevenlabs = "elevenlabs"
    
    var displayName: String {
        switch self {
        case .cartesia:
            return "Cartesia"
        case .elevenlabs:
            return "ElevenLabs"
        }
    }
    
    var defaultModel: String {
        switch self {
        case .cartesia:
            return "sonic-3"
        case .elevenlabs:
            return "eleven_turbo_v2_5"
        }
    }
}

/// TTS Voice options for each provider
/// See: https://docs.livekit.io/agents/models/tts/#inference
struct TTSVoice: Identifiable, Codable, Hashable {
    let id: String
    let provider: TTSProvider
    let name: String
    let description: String
    let voiceId: String
    let previewURL: String? // URL to preview audio sample
    
    /// Full LiveKit model identifier (e.g., "cartesia/sonic-3:voice-id")
    var fullIdentifier: String {
        return "\(provider.rawValue)/\(provider.defaultModel):\(voiceId)"
    }
    
    static let availableVoices: [TTSVoice] = [
        // Cartesia Sonic-3 voices (from LiveKit Inference)
        // See: https://docs.cartesia.ai/build-with-cartesia/tts-models/latest
        TTSVoice(id: "cartesia-katie", provider: .cartesia, name: "Katie", description: "Professional female voice for agents", voiceId: "f786b574-daa5-4673-aa0c-cbe3e8534c02", previewURL: nil),
        TTSVoice(id: "cartesia-kiefer", provider: .cartesia, name: "Kiefer", description: "Professional male voice for agents", voiceId: "228fca29-3a0a-435c-8728-5cb483251068", previewURL: nil),
        TTSVoice(id: "cartesia-tessa", provider: .cartesia, name: "Tessa", description: "Expressive and emotive female voice", voiceId: "6ccbfb76-1fc6-48f7-b71d-91ac6298247b", previewURL: nil),
        TTSVoice(id: "cartesia-kyle", provider: .cartesia, name: "Kyle", description: "Expressive and emotive male voice", voiceId: "c961b81c-a935-4c17-bfb3-ba2239de8c2f", previewURL: nil),
        
        // ElevenLabs voices (from LiveKit Inference)
        // Popular conversational voices from ElevenLabs library
        // Note: Direct API used for preview generation, LiveKit Inference used during live calls
        TTSVoice(id: "elevenlabs-rachel", provider: .elevenlabs, name: "Rachel", description: "Professional female voice", voiceId: "21m00Tcm4TlvDq8ikWAM", previewURL: nil),
        TTSVoice(id: "elevenlabs-clyde", provider: .elevenlabs, name: "Clyde", description: "Great for character use-cases", voiceId: "2EiwWnXFnvU5JabPnv8n", previewURL: nil),
        TTSVoice(id: "elevenlabs-roger", provider: .elevenlabs, name: "Roger", description: "Easy going, perfect for casual conversations", voiceId: "CwhRBWXzGAHq8TQ4Fs17", previewURL: nil),
        TTSVoice(id: "elevenlabs-sarah", provider: .elevenlabs, name: "Sarah", description: "Confident and warm young adult woman", voiceId: "EXAVITQu4vr4xnSDxMaL", previewURL: nil),
        TTSVoice(id: "elevenlabs-laura", provider: .elevenlabs, name: "Laura", description: "Young adult female, delivers sunny upbeat energy", voiceId: "FGY2WhTYpPnrIDTdsKH5", previewURL: nil),
        TTSVoice(id: "elevenlabs-charlie", provider: .elevenlabs, name: "Charlie", description: "Young Australian male, confident and natural", voiceId: "IKne3meq5aSn9XLyUdCD", previewURL: nil),
    ]
    
    static func voices(for provider: TTSProvider) -> [TTSVoice] {
        return availableVoices.filter { $0.provider == provider }
    }
    
    static var defaultVoice: TTSVoice {
        return availableVoices.first { $0.id == "cartesia-katie" } ?? availableVoices[0]
    }
}

enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "free"
    case basic = "basic"
    case pro = "pro"
    case enterprise = "enterprise"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .basic:
            return "Basic"
        case .pro:
            return "Pro"
        case .enterprise:
            return "Enterprise"
        }
    }
    
    /// Monthly minutes included in this tier
    var monthlyMinutes: Int {
        switch self {
        case .free:
            return 60 // 1 hour free per month
        case .basic:
            return 300 // 5 hours per month
        case .pro:
            return 1000 // ~16.7 hours per month
        case .enterprise:
            return -1 // Unlimited
        }
    }
    
    var description: String {
        switch self {
        case .free:
            return "\(monthlyMinutes) minutes per month"
        case .basic:
            return "\(monthlyMinutes) minutes per month"
        case .pro:
            return "\(monthlyMinutes) minutes per month"
        case .enterprise:
            return "Unlimited minutes"
        }
    }
}

@MainActor
@Observable
final class UserSettings {
    var loggingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(loggingEnabled, forKey: "loggingEnabled")
        }
    }
    
    var retentionDays: Int {
        didSet {
            UserDefaults.standard.set(retentionDays, forKey: "retentionDays")
        }
    }
    
    var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    
    var selectedModel: AIModel {
        didSet {
            UserDefaults.standard.set(selectedModel.rawValue, forKey: "selectedModel")
        }
    }
    
    var subscriptionTier: SubscriptionTier {
        didSet {
            UserDefaults.standard.set(subscriptionTier.rawValue, forKey: "subscriptionTier")
        }
    }
    
    var selectedVoice: TTSVoice {
        didSet {
            if let encoded = try? JSONEncoder().encode(selectedVoice) {
                UserDefaults.standard.set(encoded, forKey: "selectedVoice")
            }
        }
    }
    
    static let shared = UserSettings()
    
    // Retention options: 0 = Never delete, > 0 = number of days
    
    private init() {
        self.loggingEnabled = UserDefaults.standard.bool(forKey: "loggingEnabled")

        // Check if retentionDays key exists to distinguish between "not set" (default to 30) and "set to 0" (never delete)
        if UserDefaults.standard.object(forKey: "retentionDays") != nil {
            self.retentionDays = UserDefaults.standard.integer(forKey: "retentionDays")
        } else {
            self.retentionDays = 30 // Default to 30 days if not set
        }

        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        // Load selected model, default to GPT-4.1 Mini
        if let modelString = UserDefaults.standard.string(forKey: "selectedModel"),
           let model = AIModel(rawValue: modelString) {
            self.selectedModel = model
        } else {
            self.selectedModel = .gpt41Mini // Default model (openai/gpt-4.1-mini)
        }
        
        // Load subscription tier, default to free
        if let tierString = UserDefaults.standard.string(forKey: "subscriptionTier"),
           let tier = SubscriptionTier(rawValue: tierString) {
            self.subscriptionTier = tier
        } else {
            self.subscriptionTier = .free // Default tier
        }
        
        // Load selected voice, default to Cartesia Coral
        if let voiceData = UserDefaults.standard.data(forKey: "selectedVoice"),
           let voice = try? JSONDecoder().decode(TTSVoice.self, from: voiceData),
           TTSVoice.availableVoices.contains(where: { $0.id == voice.id }) {
            self.selectedVoice = voice
        } else {
            self.selectedVoice = TTSVoice.defaultVoice
        }
    }
}

