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
    
    // Settings
    @Published public var ollamaHost: String = "http://localhost:11434"
    @Published public var openAIKey: String = ""
    @Published public var anthropicKey: String = ""
    @Published public var huggingFaceToken: String = ""
    @Published public var isSettingsPresented: Bool = false
    
    public init() {
        let defaultModels = LLMModel.presetModels
        self.availableModels = defaultModels
        self.selectedModel = defaultModels[0] // Llama 3 8B
        self.parameters = LLMParameters(temperature: 0.7, maxTokens: 2000, systemPrompt: "You are a helpful assistant.")
        
        let ws1 = Workspace(name: "Current Chat", isActive: true)
        let ws2 = Workspace(name: "Research Project", isActive: false)
        let ws3 = Workspace(name: "Code Review", isActive: false)
        
        self.workspaces = [ws1, ws2, ws3]
        self.activeWorkspaceId = ws1.id
        
        self.contextFiles = [
            ContextFile(name: "project-notes.md", sizeText: "2.3 KB", isInContext: true, fileType: "md", content: "Notes on ManyLLM app architecture and design."),
            ContextFile(name: "api-docs.pdf", sizeText: "156 KB", isInContext: true, fileType: "pdf", content: "API documentation endpoints for local & remote inference."),
            ContextFile(name: "requirements.txt", sizeText: "0.8 KB", isInContext: false, fileType: "txt", content: "Dependencies: SwiftUI, Combine, URLSession.")
        ]
        
        self.chatMessages = []
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
    
    public func selectWorkspace(_ workspace: Workspace) {
        for index in workspaces.indices {
            workspaces[index].isActive = (workspaces[index].id == workspace.id)
        }
        activeWorkspaceId = workspace.id
    }
    
    public func addWorkspace(name: String) {
        let newWs = Workspace(name: name.isEmpty ? "New Workspace" : name, isActive: true)
        for index in workspaces.indices {
            workspaces[index].isActive = false
        }
        workspaces.append(newWs)
        activeWorkspaceId = newWs.id
    }
    
    public func toggleContextFile(_ file: ContextFile) {
        if let index = contextFiles.firstIndex(where: { $0.id == file.id }) {
            contextFiles[index].isInContext.toggle()
        }
    }
    
    public func sendMessage() {
        let promptText = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !promptText.isEmpty, !isGenerating else { return }
        
        let userMessage = ChatMessage(role: .user, content: promptText)
        chatMessages.append(userMessage)
        
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
                anthropicKey: anthropicKey
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
            isGenerating = false
        }
    }
}
