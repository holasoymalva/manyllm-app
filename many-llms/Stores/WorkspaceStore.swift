//
//  WorkspaceStore.swift
//  many-llms
//

import SwiftUI
import Combine

@MainActor
public final class WorkspaceStore: ObservableObject {
    @Published public var selectedModel: LLMModel
    @Published public var availableModels: [LLMModel]
    @Published public var parameters: LLMParameters
    
    @Published public var workspaces: [Workspace]
    @Published public var activeWorkspaceId: UUID
    
    @Published public var allContextFiles: [ContextFile]
    @Published public var allChatMessages: [ChatMessage]
    
    public var chatMessages: [ChatMessage] {
        allChatMessages.filter { msg in
            if let wId = msg.workspaceId {
                return wId == activeWorkspaceId
            }
            return activeWorkspaceId == (workspaces.first?.id ?? activeWorkspaceId)
        }
    }
    
    public var contextFiles: [ContextFile] {
        allContextFiles.filter { file in
            if let wId = file.workspaceId {
                return wId == activeWorkspaceId
            }
            return activeWorkspaceId == (workspaces.first?.id ?? activeWorkspaceId)
        }
    }
    
    @Published public var inputPrompt: String = ""
    @Published public var isGenerating: Bool = false
    @Published public var systemPromptExpanded: Bool = false
    
    // Settings (Persisted via StorageService)
    @Published public var ollamaHost: String {
        didSet { StorageService.shared.ollamaHost = ollamaHost }
    }
    @Published public var openAIKey: String {
        didSet { StorageService.shared.openAIKey = openAIKey }
    }
    @Published public var anthropicKey: String {
        didSet { StorageService.shared.anthropicKey = anthropicKey }
    }
    @Published public var huggingFaceToken: String {
        didSet { StorageService.shared.huggingFaceToken = huggingFaceToken }
    }
    @Published public var customEndpoint: String {
        didSet { StorageService.shared.customEndpoint = customEndpoint }
    }
    @Published public var hasConsentedToDataSharing: Bool {
        didSet { StorageService.shared.hasConsentedToDataSharing = hasConsentedToDataSharing }
    }
    @Published public var appLanguage: AppLanguage {
        didSet { StorageService.shared.appLanguage = appLanguage }
    }
    @Published public var isSettingsPresented: Bool = false
    
    // Ollama Connection Status
    @Published public var ollamaStatusMessage: String = "No comprobado"
    @Published public var isOllamaConnected: Bool = false
    @Published public var isTestingConnection: Bool = false
    
    public init() {
        let storage = StorageService.shared
        
        self.ollamaHost = storage.ollamaHost
        self.openAIKey = storage.openAIKey
        self.anthropicKey = storage.anthropicKey
        self.huggingFaceToken = storage.huggingFaceToken
        self.customEndpoint = storage.customEndpoint
        self.hasConsentedToDataSharing = storage.hasConsentedToDataSharing
        self.appLanguage = storage.appLanguage
        
        self.parameters = LLMParameters(
            temperature: storage.temperature,
            maxTokens: storage.maxTokens,
            systemPrompt: storage.systemPrompt
        )
        
        let defaultModels = LLMModel.presetModels
        self.availableModels = defaultModels
        
        let savedModelId = storage.selectedModelId
        self.selectedModel = defaultModels.first(where: { $0.id == savedModelId }) ?? defaultModels[0]
        
        // 1. Initialize Workspaces
        var isNewWorkspaces = false
        if let savedWorkspaces = storage.loadWorkspaces(), !savedWorkspaces.isEmpty {
            self.workspaces = savedWorkspaces
            self.activeWorkspaceId = savedWorkspaces.first(where: { $0.isActive })?.id ?? savedWorkspaces[0].id
        } else {
            let ws1 = Workspace(name: "Current Chat", isActive: true)
            let ws2 = Workspace(name: "Research Project", isActive: false)
            let ws3 = Workspace(name: "Code Review", isActive: false)
            self.workspaces = [ws1, ws2, ws3]
            self.activeWorkspaceId = ws1.id
            isNewWorkspaces = true
        }
        
        // 2. Initialize Context Files
        var isNewContextFiles = false
        if let savedFiles = storage.loadContextFiles(), !savedFiles.isEmpty {
            self.allContextFiles = savedFiles
        } else {
            let defaultWsId = self.activeWorkspaceId
            self.allContextFiles = [
                ContextFile(workspaceId: defaultWsId, name: "project-notes.md", sizeText: "2.3 KB", isInContext: true, fileType: "md", content: "Notes on ManyLLM app architecture and design."),
                ContextFile(workspaceId: defaultWsId, name: "api-docs.pdf", sizeText: "156 KB", isInContext: true, fileType: "pdf", content: "API documentation endpoints for local & remote inference."),
                ContextFile(workspaceId: defaultWsId, name: "requirements.txt", sizeText: "0.8 KB", isInContext: false, fileType: "txt", content: "Dependencies: SwiftUI, Combine, URLSession.")
            ]
            isNewContextFiles = true
        }
        
        // 3. Initialize Chat Messages
        self.allChatMessages = storage.loadChatMessages()
        
        // Phase 2: Save defaults to storage if newly created
        if isNewWorkspaces {
            storage.saveWorkspaces(self.workspaces)
        }
        if isNewContextFiles {
            storage.saveContextFiles(self.allContextFiles)
        }
        
        // Initial Ollama Auto-Discovery
        Task {
            await checkOllamaConnection()
        }
    }
    
    public var activeFilesCountText: String {
        let activeCount = contextFiles.filter { $0.isInContext }.count
        return String(format: loc("files_in_context"), activeCount, contextFiles.count)
    }
    
    public var wordCount: Int {
        let trimmed = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        return trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    public func updateParameters(temp: Double, maxTok: Int, prompt: String) {
        parameters.temperature = temp
        parameters.maxTokens = maxTok
        parameters.systemPrompt = prompt
        
        StorageService.shared.temperature = temp
        StorageService.shared.maxTokens = maxTok
        StorageService.shared.systemPrompt = prompt
    }
    
    public func selectModel(_ model: LLMModel) {
        selectedModel = model
        StorageService.shared.selectedModelId = model.id
    }
    
    public func selectWorkspace(_ workspace: Workspace) {
        objectWillChange.send()
        for index in workspaces.indices {
            workspaces[index].isActive = (workspaces[index].id == workspace.id)
        }
        activeWorkspaceId = workspace.id
        StorageService.shared.saveWorkspaces(workspaces)
    }
    
    public func addWorkspace(name: String) {
        objectWillChange.send()
        let newWs = Workspace(name: name.isEmpty ? "New Workspace" : name, isActive: true)
        for index in workspaces.indices {
            workspaces[index].isActive = false
        }
        workspaces.append(newWs)
        activeWorkspaceId = newWs.id
        StorageService.shared.saveWorkspaces(workspaces)
    }
    
    public func toggleContextFile(_ file: ContextFile) {
        objectWillChange.send()
        if let index = allContextFiles.firstIndex(where: { $0.id == file.id }) {
            allContextFiles[index].isInContext.toggle()
            StorageService.shared.saveContextFiles(allContextFiles)
        }
    }
    
    public func addCustomContextFile(name: String, content: String) {
        objectWillChange.send()
        let sizeText = "\(Double(content.count) / 1024.0 < 0.1 ? 0.1 : Double(content.count) / 1024.0) KB"
        let newFile = ContextFile(workspaceId: activeWorkspaceId, name: name, sizeText: sizeText, isInContext: true, fileType: "txt", content: content)
        allContextFiles.append(newFile)
        StorageService.shared.saveContextFiles(allContextFiles)
    }
    
    public func checkOllamaConnection() async {
        isTestingConnection = true
        let (isSuccess, message, _) = await LLMService.shared.testOllamaConnection(host: ollamaHost)
        isOllamaConnected = isSuccess
        ollamaStatusMessage = message
        
        if isSuccess {
            if let realOllamaModels = try? await LLMService.shared.fetchOllamaModels(host: ollamaHost), !realOllamaModels.isEmpty {
                var combined = availableModels.filter { $0.provider != .ollama }
                combined.insert(contentsOf: realOllamaModels, at: 0)
                availableModels = combined
                
                if selectedModel.provider == .ollama {
                    if let updated = realOllamaModels.first(where: { $0.id == selectedModel.id }) ?? realOllamaModels.first {
                        selectedModel = updated
                    }
                }
            }
        }
        isTestingConnection = false
    }
    
    public func sendMessage() {
        let promptText = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !promptText.isEmpty, !isGenerating else { return }
        
        objectWillChange.send()
        let currentWorkspaceId = activeWorkspaceId
        let userMessage = ChatMessage(workspaceId: currentWorkspaceId, role: .user, content: promptText)
        allChatMessages.append(userMessage)
        StorageService.shared.saveChatMessages(allChatMessages)
        
        inputPrompt = ""
        isGenerating = true
        
        let assistantMessageId = UUID()
        let initialAssistantMsg = ChatMessage(id: assistantMessageId, workspaceId: currentWorkspaceId, role: .assistant, content: "", modelName: selectedModel.name)
        allChatMessages.append(initialAssistantMsg)
        
        let activeContextFiles = self.contextFiles
        let activeMessages = self.chatMessages
        
        Task {
            let stream = LLMService.shared.streamCompletion(
                model: selectedModel,
                prompt: promptText,
                messages: Array(activeMessages.dropLast()),
                contextFiles: activeContextFiles,
                parameters: parameters,
                ollamaHost: ollamaHost,
                openAIKey: openAIKey,
                anthropicKey: anthropicKey,
                huggingFaceToken: huggingFaceToken,
                customEndpoint: customEndpoint
            )
            
            do {
                for try await chunk in stream {
                    if let index = allChatMessages.firstIndex(where: { $0.id == assistantMessageId }) {
                        allChatMessages[index].content += chunk
                    }
                }
            } catch {
                if let index = allChatMessages.firstIndex(where: { $0.id == assistantMessageId }) {
                    allChatMessages[index].content += "\n[Error: \(error.localizedDescription)]"
                }
            }
            StorageService.shared.saveChatMessages(allChatMessages)
            isGenerating = false
        }
    }
    
    public func clearChatHistory() {
        objectWillChange.send()
        let currentWorkspaceId = activeWorkspaceId
        allChatMessages.removeAll { msg in
            if let wId = msg.workspaceId {
                return wId == currentWorkspaceId
            }
            return currentWorkspaceId == workspaces.first?.id
        }
        StorageService.shared.saveChatMessages(allChatMessages)
    }
    
    public func loc(_ key: String) -> String {
        LocalizationManager.shared.localizedString(forKey: key, language: appLanguage)
    }
}
