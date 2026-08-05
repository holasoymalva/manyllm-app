//
//  StorageService.swift
//  many-llms
//

import Foundation

public final class StorageService {
    public static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let ollamaHost = "manyllm_ollama_host"
        static let openAIKey = "manyllm_openai_key"
        static let anthropicKey = "manyllm_anthropic_key"
        static let huggingFaceToken = "manyllm_hf_token"
        static let customEndpoint = "manyllm_custom_endpoint"
        static let selectedModelId = "manyllm_selected_model_id"
        static let temperature = "manyllm_temperature"
        static let maxTokens = "manyllm_max_tokens"
        static let systemPrompt = "manyllm_system_prompt"
        static let hasConsentedToDataSharing = "manyllm_data_sharing_consent"
        static let appLanguage = "manyllm_app_language"
    }
    
    // MARK: - UserDefaults Properties
    public var appLanguage: AppLanguage {
        get {
            if let raw = userDefaults.string(forKey: Keys.appLanguage), let lang = AppLanguage(rawValue: raw) {
                return lang
            }
            return .system
        }
        set { userDefaults.set(newValue.rawValue, forKey: Keys.appLanguage) }
    }
    
    public var hasConsentedToDataSharing: Bool {
        get { userDefaults.bool(forKey: Keys.hasConsentedToDataSharing) }
        set { userDefaults.set(newValue, forKey: Keys.hasConsentedToDataSharing) }
    }
    
    public var ollamaHost: String {
        get { userDefaults.string(forKey: Keys.ollamaHost) ?? "http://localhost:11434" }
        set { userDefaults.set(newValue, forKey: Keys.ollamaHost) }
    }
    
    public var openAIKey: String {
        get { userDefaults.string(forKey: Keys.openAIKey) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.openAIKey) }
    }
    
    public var anthropicKey: String {
        get { userDefaults.string(forKey: Keys.anthropicKey) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.anthropicKey) }
    }
    
    public var huggingFaceToken: String {
        get { userDefaults.string(forKey: Keys.huggingFaceToken) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.huggingFaceToken) }
    }
    
    public var customEndpoint: String {
        get { userDefaults.string(forKey: Keys.customEndpoint) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.customEndpoint) }
    }
    
    public var selectedModelId: String {
        get { userDefaults.string(forKey: Keys.selectedModelId) ?? "llama3:8b" }
        set { userDefaults.set(newValue, forKey: Keys.selectedModelId) }
    }
    
    public var temperature: Double {
        get {
            let val = userDefaults.double(forKey: Keys.temperature)
            return val == 0 ? 0.7 : val
        }
        set { userDefaults.set(newValue, forKey: Keys.temperature) }
    }
    
    public var maxTokens: Int {
        get {
            let val = userDefaults.integer(forKey: Keys.maxTokens)
            return val == 0 ? 2000 : val
        }
        set { userDefaults.set(newValue, forKey: Keys.maxTokens) }
    }
    
    public var systemPrompt: String {
        get { userDefaults.string(forKey: Keys.systemPrompt) ?? "You are a helpful assistant." }
        set { userDefaults.set(newValue, forKey: Keys.systemPrompt) }
    }
    
    // MARK: - File System Storage
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var workspacesFileURL: URL {
        documentsDirectory.appendingPathComponent("workspaces.json")
    }
    
    private var chatMessagesFileURL: URL {
        documentsDirectory.appendingPathComponent("chat_messages.json")
    }
    
    private var contextFilesFileURL: URL {
        documentsDirectory.appendingPathComponent("context_files.json")
    }
    
    // MARK: - Save & Load Workspaces
    public func saveWorkspaces(_ workspaces: [Workspace]) {
        do {
            let data = try JSONEncoder().encode(workspaces)
            try data.write(to: workspacesFileURL, options: .atomic)
        } catch {
            print("Error saving workspaces: \(error)")
        }
    }
    
    public func loadWorkspaces() -> [Workspace]? {
        guard fileManager.fileExists(atPath: workspacesFileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: workspacesFileURL)
            return try JSONDecoder().decode([Workspace].self, from: data)
        } catch {
            print("Error loading workspaces: \(error)")
            return nil
        }
    }
    
    // MARK: - Save & Load Chat Messages
    public func saveChatMessages(_ messages: [ChatMessage]) {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: chatMessagesFileURL, options: .atomic)
        } catch {
            print("Error saving chat messages: \(error)")
        }
    }
    
    public func loadChatMessages() -> [ChatMessage] {
        guard fileManager.fileExists(atPath: chatMessagesFileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: chatMessagesFileURL)
            return try JSONDecoder().decode([ChatMessage].self, from: data)
        } catch {
            print("Error loading chat messages: \(error)")
            return []
        }
    }
    
    // MARK: - Save & Load Context Files
    public func saveContextFiles(_ files: [ContextFile]) {
        do {
            let data = try JSONEncoder().encode(files)
            try data.write(to: contextFilesFileURL, options: .atomic)
        } catch {
            print("Error saving context files: \(error)")
        }
    }
    
    public func loadContextFiles() -> [ContextFile]? {
        guard fileManager.fileExists(atPath: contextFilesFileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: contextFilesFileURL)
            return try JSONDecoder().decode([ContextFile].self, from: data)
        } catch {
            print("Error loading context files: \(error)")
            return nil
        }
    }
}
