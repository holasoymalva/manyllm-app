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
    
    @Published public var contextFiles: [ContextFile]
    @Published public var chatMessages: [ChatMessage]
    
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
    @Published public var isSettingsPresented: Bool = false
    
    // Ollama Connection Status
    @Published public var ollamaStatusMessage: String = "No comprobado"
    @Published public var isOllamaConnected: Bool = false
    @Published public var isTestingConnection: Bool = false
    
    public init() {
        let storage = StorageService.shared
        
        let initialOllamaHost = storage.ollamaHost
        let initialOpenAIKey = storage.openAIKey
        let initialAnthropicKey = storage.anthropicKey
        let initialHFToken = storage.huggingFaceToken
        let initialCustomEndpoint = storage.customEndpoint
        
        self.ollamaHost = initialOllamaHost
        self.openAIKey = initialOpenAIKey
        self.anthropicKey = initialAnthropicKey
        self.huggingFaceToken = initialHFToken
        self.customEndpoint = initialCustomEndpoint
        
        self.parameters = LLMParameters(
            temperature: storage.temperature,
            maxTokens: storage.maxTokens,
            systemPrompt: storage.systemPrompt
        )
        
        let defaultModels = LLMModel.presetModels
        self.availableModels = defaultModels
        
        let savedModelId = storage.selectedModelId
        self.selectedModel = defaultModels.first(where: { $0.id == savedModelId }) ?? defaultModels[0]
        
        // Load persistent Workspaces
        if let savedWorkspaces = storage.loadWorkspaces(), !savedWorkspaces.isEmpty {
            self.workspaces = savedWorkspaces
            self.activeWorkspaceId = savedWorkspaces.first(where: { $0.isActive })?.id ?? savedWorkspaces[0].id
        } else {
            let ws1 = Workspace(name: "Current Chat", isActive: true)
            let ws2 = Workspace(name: "Research Project", isActive: false)
            let ws3 = Workspace(name: "Code Review", isActive: false)
            self.workspaces = [ws1, ws2, ws3]
            self.activeWorkspaceId = ws1.id
            storage.saveWorkspaces(self.workspaces)
        }
        
        // Load persistent Context Files
        if let savedFiles = storage.loadContextFiles(), !savedFiles.isEmpty {
            self.contextFiles = savedFiles
        } else {
            self.contextFiles = [
                ContextFile(name: "project-notes.md", sizeText: "2.3 KB", isInContext: true, fileType: "md", content: "Notes on ManyLLM app architecture and design."),
                ContextFile(name: "api-docs.pdf", sizeText: "156 KB", isInContext: true, fileType: "pdf", content: "API documentation endpoints for local & remote inference."),
                ContextFile(name: "requirements.txt", sizeText: "0.8 KB", isInContext: false, fileType: "txt", content: "Dependencies: SwiftUI, Combine, URLSession.")
            ]
            storage.saveContextFiles(self.contextFiles)
        }
        
        // Load persistent Chat Messages
        self.chatMessages = storage.loadChatMessages()
        
        // Initial Ollama Auto-Discovery
        Task {
            await checkOllamaConnection()
        }
    }
    
    public var activeFilesCountText: String {
        let activeCount = contextFiles.filter { $0.isInContext }.count
        return "\(activeCount) of \(contextFiles.count) files in context"
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
        for index in workspaces.indices {
            workspaces[index].isActive = (workspaces[index].id == workspace.id)
        }
        activeWorkspaceId = workspace.id
        StorageService.shared.saveWorkspaces(workspaces)
    }
    
    public func addWorkspace(name: String) {
        let newWs = Workspace(name: name.isEmpty ? "New Workspace" : name, isActive: true)
        for index in workspaces.indices {
            workspaces[index].isActive = false
        }
        workspaces.append(newWs)
        activeWorkspaceId = newWs.id
        StorageService.shared.saveWorkspaces(workspaces)
    }
    
    public func toggleContextFile(_ file: ContextFile) {
        if let index = contextFiles.firstIndex(where: { $0.id == file.id }) {
            contextFiles[index].isInContext.toggle()
            StorageService.shared.saveContextFiles(contextFiles)
        }
    }
    
    public func addCustomContextFile(name: String, content: String) {
        let sizeText = "\(Double(content.count) / 1024.0 < 0.1 ? 0.1 : Double(content.count) / 1024.0) KB"
        let newFile = ContextFile(name: name, sizeText: sizeText, isInContext: true, fileType: "txt", content: content)
        contextFiles.append(newFile)
        StorageService.shared.saveContextFiles(contextFiles)
    }
    
    public func checkOllamaConnection() async {
        isTestingConnection = true
        let (isSuccess, message, _) = await LLMService.shared.testOllamaConnection(host: ollamaHost)
        isOllamaConnected = isSuccess
        ollamaStatusMessage = message
        
        if isSuccess {
            if let realOllamaModels = try? await LLMService.shared.fetchOllamaModels(host: ollamaHost), !realOllamaModels.isEmpty {
                // Merge discovered Ollama models with preset models
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
        
        let userMessage = ChatMessage(role: .user, content: promptText)
        chatMessages.append(userMessage)
        StorageService.shared.saveChatMessages(chatMessages)
        
        inputPrompt = ""
        isGenerating = true
        
        let assistantMessageId = UUID()
        let initialAssistantMsg = ChatMessage(id: assistantMessageId, role: .assistant, content: "", modelName: selectedModel.name)
        chatMessages.append(initialAssistantMsg)
        
        Task {
            let stream = LLMService.shared.streamCompletion(
                model: selectedModel,
                prompt: promptText,
                messages: Array(chatMessages.dropLast()),
                contextFiles: contextFiles,
                parameters: parameters,
                ollamaHost: ollamaHost,
                openAIKey: openAIKey,
                anthropicKey: anthropicKey,
                huggingFaceToken: huggingFaceToken,
                customEndpoint: customEndpoint
            )
            
            do {
                for try await chunk in stream {
                    if let index = chatMessages.firstIndex(where: { $0.id == assistantMessageId }) {
                        chatMessages[index].content += chunk
                    }
                }
            } catch {
                if let index = chatMessages.firstIndex(where: { $0.id == assistantMessageId }) {
                    chatMessages[index].content += "\n[Error: \(error.localizedDescription)]"
                }
            }
            StorageService.shared.saveChatMessages(chatMessages)
            isGenerating = false
        }
    }
    
    public func clearChatHistory() {
        chatMessages.removeAll()
        StorageService.shared.saveChatMessages([])
    }
}
