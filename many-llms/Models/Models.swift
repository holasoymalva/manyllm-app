//
//  Models.swift
//  many-llms
//

import Foundation

public enum LLMProvider: String, Codable, CaseIterable, Identifiable {
    case ollama = "Ollama"
    case llamaCpp = "llama.cpp"
    case mlx = "MLX"
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case huggingFace = "HuggingFace"
    
    public var id: String { rawValue }
}

public struct LLMModel: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let provider: LLMProvider
    public let engineLabel: String
    public let isLocal: Bool
    public let description: String
    
    public init(id: String, name: String, provider: LLMProvider, engineLabel: String, isLocal: Bool, description: String = "") {
        self.id = id
        self.name = name
        self.provider = provider
        self.engineLabel = engineLabel
        self.isLocal = isLocal
        self.description = description
    }
    
    public static let presetModels: [LLMModel] = [
        LLMModel(id: "llama3:8b", name: "Llama 3 8B", provider: .ollama, engineLabel: "Ollama", isLocal: true, description: "Meta's performant 8B parameter model"),
        LLMModel(id: "mistral:7b", name: "Mistral 7B", provider: .ollama, engineLabel: "Ollama", isLocal: true, description: "Mistral AI 7B instruct model"),
        LLMModel(id: "qwen2:7b", name: "Qwen 7B", provider: .llamaCpp, engineLabel: "llama.cpp", isLocal: true, description: "Alibaba Qwen 7B GGUF quantized"),
        LLMModel(id: "phi3:mini", name: "Phi-3 Mini", provider: .mlx, engineLabel: "MLX", isLocal: true, description: "Microsoft Phi-3 Mini 3.8B optimized for Apple Silicon"),
        LLMModel(id: "gpt-4o", name: "GPT-4o", provider: .openAI, engineLabel: "OpenAI API", isLocal: false, description: "OpenAI flagship multimodal model"),
        LLMModel(id: "claude-3-5-sonnet", name: "Claude 3.5 Sonnet", provider: .anthropic, engineLabel: "Anthropic API", isLocal: false, description: "Anthropic's most intelligent model"),
        LLMModel(id: "hf-deepseek-r1", name: "DeepSeek R1", provider: .huggingFace, engineLabel: "HuggingFace", isLocal: false, description: "DeepSeek R1 reasoning model via HF Hub")
    ]
}

public struct Workspace: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var isActive: Bool
    public var createdAt: Date
    
    public init(id: UUID = UUID(), name: String, isActive: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

public struct ContextFile: Identifiable, Hashable, Codable {
    public let id: UUID
    public var workspaceId: UUID?
    public var name: String
    public var sizeText: String
    public var isInContext: Bool
    public var fileType: String
    public var content: String
    
    public init(id: UUID = UUID(), workspaceId: UUID? = nil, name: String, sizeText: String, isInContext: Bool = true, fileType: String = "md", content: String = "") {
        self.id = id
        self.workspaceId = workspaceId
        self.name = name
        self.sizeText = sizeText
        self.isInContext = isInContext
        self.fileType = fileType
        self.content = content
    }
}

public enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}

public struct ChatMessage: Identifiable, Hashable, Codable {
    public let id: UUID
    public var workspaceId: UUID?
    public let role: MessageRole
    public var content: String
    public let timestamp: Date
    public let modelName: String?
    
    public init(id: UUID = UUID(), workspaceId: UUID? = nil, role: MessageRole, content: String, timestamp: Date = Date(), modelName: String? = nil) {
        self.id = id
        self.workspaceId = workspaceId
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.modelName = modelName
    }
}

public struct LLMParameters: Codable {
    public var temperature: Double
    public var maxTokens: Int
    public var systemPrompt: String
    
    public init(temperature: Double = 0.7, maxTokens: Int = 2000, systemPrompt: String = "You are a helpful, knowledgeable AI assistant.") {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.systemPrompt = systemPrompt
    }
}
