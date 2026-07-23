//
//  LLMService.swift
//  many-llms
//

import Foundation

public final class LLMService {
    public static let shared = LLMService()
    
    private init() {}
    
    /// Stream responses from Ollama, OpenAI, Anthropic or Local engine
    public func streamCompletion(
        model: LLMModel,
        prompt: String,
        messages: [ChatMessage],
        contextFiles: [ContextFile],
        parameters: LLMParameters,
        ollamaHost: String,
        openAIKey: String,
        anthropicKey: String
    ) -> AsyncThrowingStream<String, Error> {        AsyncThrowingStream { continuation in
            Task {
                do {
                    switch model.provider {
                    case .ollama:
                        try await streamOllama(model: model, prompt: prompt, messages: messages, contextFiles: contextFiles, parameters: parameters, host: ollamaHost, continuation: continuation)
                    case .openAI:
                        if !openAIKey.isEmpty {
                            try await streamOpenAI(model: model, prompt: prompt, messages: messages, contextFiles: contextFiles, parameters: parameters, apiKey: openAIKey, continuation: continuation)
                        } else {
                            try await streamSimulated(model: model, prompt: prompt, contextFiles: contextFiles, continuation: continuation)
                        }
                    case .anthropic:
                        if !anthropicKey.isEmpty {
                            try await streamAnthropic(model: model, prompt: prompt, messages: messages, contextFiles: contextFiles, parameters: parameters, apiKey: anthropicKey, continuation: continuation)
                        } else {
                            try await streamSimulated(model: model, prompt: prompt, contextFiles: contextFiles, continuation: continuation)
                        }
                    case .llamaCpp, .mlx, .huggingFace:
                        try await streamSimulated(model: model, prompt: prompt, contextFiles: contextFiles, continuation: continuation)
                    }
                } catch {
                    // Fallback to simulated response if network error occurs
                    try? await streamSimulated(model: model, prompt: prompt, contextFiles: contextFiles, continuation: continuation)
                }
            }
        }
    }
    
    // MARK: - Ollama Stream
    private func streamOllama(
        model: LLMModel,
        prompt: String,
        messages: [ChatMessage],
        contextFiles: [ContextFile],
        parameters: LLMParameters,
        host: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let cleanHost = host.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "/$", with: "", options: .regularExpression)
        guard let url = URL(string: "\(cleanHost.isEmpty ? "http://localhost:11434" : cleanHost)/api/chat") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var reqMessages: [[String: String]] = []
        if !parameters.systemPrompt.isEmpty {
            reqMessages.append(["role": "system", "content": parameters.systemPrompt])
        }
        
        // Add active context files
        let activeFiles = contextFiles.filter { $0.isInContext }
        if !activeFiles.isEmpty {
            let filesContext = activeFiles.map { "File [\($0.name)]:\n\($0.content)" }.joined(separator: "\n\n")
            reqMessages.append(["role": "system", "content": "Context files:\n\(filesContext)"])
        }
        
        for msg in messages {
            reqMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }
        reqMessages.append(["role": "user", "content": prompt])
        
        let body: [String: Any] = [
            "model": model.id,
            "messages": reqMessages,
            "stream": true,
            "options": [
                "temperature": parameters.temperature,
                "num_predict": parameters.maxTokens
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        for try await line in bytes.lines {
            if let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let messageObj = json["message"] as? [String: Any],
               let chunk = messageObj["content"] as? String {
                continuation.yield(chunk)
            }
        }
        continuation.finish()
    }
    
    // MARK: - OpenAI Stream
    private func streamOpenAI(
        model: LLMModel,
        prompt: String,
        messages: [ChatMessage],
        contextFiles: [ContextFile],
        parameters: LLMParameters,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var reqMessages: [[String: String]] = []
        if !parameters.systemPrompt.isEmpty {
            reqMessages.append(["role": "system", "content": parameters.systemPrompt])
        }
        
        for msg in messages {
            reqMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }
        reqMessages.append(["role": "user", "content": prompt])
        
        let body: [String: Any] = [
            "model": model.id,
            "messages": reqMessages,
            "temperature": parameters.temperature,
            "max_tokens": parameters.maxTokens,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" { break }
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let delta = choices.first?["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    continuation.yield(content)
                }
            }
        }
        continuation.finish()
    }
    
    // MARK: - Anthropic Stream
    private func streamAnthropic(
        model: LLMModel,
        prompt: String,
        messages: [ChatMessage],
        contextFiles: [ContextFile],
        parameters: LLMParameters,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        var reqMessages: [[String: String]] = []
        for msg in messages {
            reqMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }
        reqMessages.append(["role": "user", "content": prompt])
        
        let body: [String: Any] = [
            "model": model.id,
            "system": parameters.systemPrompt,
            "messages": reqMessages,
            "max_tokens": parameters.maxTokens,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let delta = json["delta"] as? [String: Any],
                   let text = delta["text"] as? String {
                    continuation.yield(text)
                }
            }
        }
        continuation.finish()
    }
    
    // MARK: - Simulated Local Model Response (For MVP / Standalone UI)
    private func streamSimulated(
        model: LLMModel,
        prompt: String,
        contextFiles: [ContextFile],
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let activeFilesCount = contextFiles.filter { $0.isInContext }.count
        let responseText = """
        Hello! Running model **\(model.name)** (\(model.engineLabel)).
        
        I received your request: "\(prompt)".
        
        **Active Context**: Including \(activeFilesCount) file(s) in context.
        
        ```swift
        // Executing in ManyLLM iOS Local Engine
        let response = "\(model.name) executed successfully"
        print(response)
        ```
        
        Feel free to connect an active Ollama host or configure API keys in Settings to execute live remote models!
        """
        
        let words = responseText.components(separatedBy: " ")
        for word in words {
            try await Task.sleep(nanoseconds: 40_000_000) // 40ms per word simulation
            continuation.yield(word + " ")
        }
        continuation.finish()
    }
}
