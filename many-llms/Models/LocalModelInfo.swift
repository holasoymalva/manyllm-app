//
//  LocalModelInfo.swift
//  many-llms
//  v1.2 Feature - Edge AI Engine
//

import Foundation
import Combine

public enum ModelDownloadState: Equatable, Codable, Hashable {
    case notDownloaded
    case downloading(progress: Double, speedMBps: Double)
    case ready(filePath: String)
    case failed(error: String)
    
    enum CodingKeys: String, CodingKey {
        case type, progress, speedMBps, filePath, error
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "ready":
            let path = try container.decode(String.self, forKey: .filePath)
            self = .ready(filePath: path)
        case "failed":
            let err = try container.decode(String.self, forKey: .error)
            self = .failed(error: err)
        case "downloading":
            let prog = try container.decode(Double.self, forKey: .progress)
            let speed = try container.decode(Double.self, forKey: .speedMBps)
            self = .downloading(progress: prog, speedMBps: speed)
        default:
            self = .notDownloaded
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .notDownloaded:
            try container.encode("notDownloaded", forKey: .type)
        case .downloading(let progress, let speedMBps):
            try container.encode("downloading", forKey: .type)
            try container.encode(progress, forKey: .progress)
            try container.encode(speedMBps, forKey: .speedMBps)
        case .ready(let filePath):
            try container.encode("ready", forKey: .type)
            try container.encode(filePath, forKey: .filePath)
        case .failed(let error):
            try container.encode("failed", forKey: .type)
            try container.encode(error, forKey: .error)
        }
    }
}

public struct LocalModelInfo: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let repoId: String
    public let fileName: String
    public let downloadURLString: String
    public let quantization: String
    public let parameterCount: String
    public let estimatedRAMBytes: Int64
    public let fileSizeBytes: Int64
    public var state: ModelDownloadState
    public var description: String
    
    public var engineLabel: String {
        return "Metal GPU (llama.cpp)"
    }
    
    public init(
        id: String,
        name: String,
        repoId: String,
        fileName: String,
        downloadURLString: String,
        quantization: String,
        parameterCount: String,
        estimatedRAMBytes: Int64,
        fileSizeBytes: Int64,
        state: ModelDownloadState = .notDownloaded,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.repoId = repoId
        self.fileName = fileName
        self.downloadURLString = downloadURLString
        self.quantization = quantization
        self.parameterCount = parameterCount
        self.estimatedRAMBytes = estimatedRAMBytes
        self.fileSizeBytes = fileSizeBytes
        self.state = state
        self.description = description
    }
    
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }
    
    public var formattedRAMRequired: String {
        ByteCountFormatter.string(fromByteCount: estimatedRAMBytes, countStyle: .memory)
    }
    
    public var isDownloaded: Bool {
        if case .ready = state { return true }
        return false
    }
    
    // Preset curated models for iOS / iPadOS
    public static let presetLocalModels: [LocalModelInfo] = [
        LocalModelInfo(
            id: "deepseek-r1-distill-qwen-1.5b-q4",
            name: "DeepSeek R1 Distill 1.5B",
            repoId: "unsloth/DeepSeek-R1-Distill-Qwen-1.5B-GGUF",
            fileName: "DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
            downloadURLString: "https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
            quantization: "Q4_K_M",
            parameterCount: "1.5B",
            estimatedRAMBytes: 1_400_000_000, // ~1.4 GB RAM
            fileSizeBytes: 1_120_000_000,
            description: "DeepSeek R1 reasoning model distilled into Qwen 1.5B. Ultra-fast, ideal for all iPhones."
        ),
        LocalModelInfo(
            id: "llama-3.2-1b-q4",
            name: "Llama 3.2 1B Instruct",
            repoId: "bartowski/Llama-3.2-1B-Instruct-GGUF",
            fileName: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
            downloadURLString: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
            quantization: "Q4_K_M",
            parameterCount: "1B",
            estimatedRAMBytes: 1_100_000_000, // ~1.1 GB RAM
            fileSizeBytes: 880_000_000,
            description: "Meta's lightweight 1B instruct model. High speed, minimal battery impact."
        ),
        LocalModelInfo(
            id: "llama-3.2-3b-q4",
            name: "Llama 3.2 3B Instruct",
            repoId: "bartowski/Llama-3.2-3B-Instruct-GGUF",
            fileName: "Llama-3.2-3B-Instruct-Q4_K_M.gguf",
            downloadURLString: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf",
            quantization: "Q4_K_M",
            parameterCount: "3B",
            estimatedRAMBytes: 2_400_000_000, // ~2.4 GB RAM
            fileSizeBytes: 2_020_000_000,
            description: "Meta's balanced 3B instruct model. Excellent coding and general reasoning."
        ),
        LocalModelInfo(
            id: "qwen-2.5-coder-1.5b-q4",
            name: "Qwen 2.5 Coder 1.5B",
            repoId: "Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF",
            fileName: "qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            downloadURLString: "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf",
            quantization: "Q4_K_M",
            parameterCount: "1.5B",
            estimatedRAMBytes: 1_500_000_000,
            fileSizeBytes: 1_180_000_000,
            description: "Alibaba's specialized coding model optimized for Swift, Python, JS and algorithms."
        ),
        LocalModelInfo(
            id: "deepseek-r1-distill-qwen-7b-q4",
            name: "DeepSeek R1 Distill 7B",
            repoId: "unsloth/DeepSeek-R1-Distill-Qwen-7B-GGUF",
            fileName: "DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf",
            downloadURLString: "https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf",
            quantization: "Q4_K_M",
            parameterCount: "7B",
            estimatedRAMBytes: 5_200_000_000, // ~5.2 GB RAM (Requires 8GB+ RAM iPad or iPhone Pro)
            fileSizeBytes: 4_680_000_000,
            description: "DeepSeek R1 reasoning model distilled into Qwen 7B. Recommended for iPad M-Series or Mac."
        )
    ]
}
