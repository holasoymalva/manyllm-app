//
//  LLMService.swift
//  many-llms
//

import Foundation

public final class LLMService {
    public static let shared = LLMService()
    
    private init() {}
    
    /// Stream responses from Ollama, OpenAI, Anthropic, HuggingFace or Local engine
    public func streamCompletion(
        model: LLMModel,
        prompt: String,
        messages: [ChatMessage],
        contextFiles: [ContextFile],
        parameters: LLMParameters,
        ollamaHost: String,
        openAIKey: String,
        anthropicKey: String,
        huggingFaceToken: String = ""
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    switch model.provider {
                    case .ollama:
                        try await streamOllama(model: model, prompt: prompt, messages: messages, contextFiles: contextFiles, parameters: parameters, host: ollamaHost, continuation: continuation)
                    case .openAI:
                        if !openAIKey.isEmpty {
                            try await streamOpenAI(model: model, prompt: prompt, messages: messages, contextFiles: contextFiles, parameters: parameters, apiKey: openAIKey, continuation: continuation)
                        } else {
                            try await streamApiKeyRequired(providerName: "OpenAI", continuation: continuation)
                        }
                    case .anthropic:
                        if !anthropicKey.isEmpty {
                            try await streamAnthropic(model: model, prompt: prompt, messages: messages, contextFiles: contextFiles, parameters: parameters, apiKey: anthropicKey, continuation: continuation)
                        } else {
                            try await streamApiKeyRequired(providerName: "Anthropic", continuation: continuation)
                        }
                    case .huggingFace:
                        if !huggingFaceToken.isEmpty {
                            try await streamHuggingFace(model: model, prompt: prompt, apiKey: huggingFaceToken, continuation: continuation)
                        } else {
                            try await streamApiKeyRequired(providerName: "Hugging Face", continuation: continuation)
                        }
                    case .llamaCpp, .mlx:
                        try await streamSimulated(model: model, prompt: prompt, contextFiles: contextFiles, continuation: continuation)
                    }
                } catch {
                    if model.provider == .ollama {
                        try? await streamOllamaError(host: ollamaHost, continuation: continuation)
                    } else {
                        try? await streamSimulated(model: model, prompt: prompt, contextFiles: contextFiles, continuation: continuation)
                    }
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
        let hostURLString = cleanHost.isEmpty ? "http://localhost:11434" : cleanHost
        
        guard let url = URL(string: "\(hostURLString)/api/chat") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        var reqMessages: [[String: String]] = []
        if !parameters.systemPrompt.isEmpty {
            reqMessages.append(["role": "system", "content": parameters.systemPrompt])
        }
        
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
    
    // MARK: - HuggingFace Stream
    private func streamHuggingFace(
        model: LLMModel,
        prompt: String,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let modelId = "deepseek-ai/DeepSeek-R1"
        guard let url = URL(string: "https://api-inference.huggingface.co/models/\(modelId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "inputs": prompt,
            "parameters": ["max_new_tokens": 1000]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if (response as? HTTPURLResponse)?.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let text = json.first?["generated_text"] as? String {
                continuation.yield(text)
            }
        } else {
            throw URLError(.badServerResponse)
        }
        continuation.finish()
    }
    
    // MARK: - Helpful Status Messages
    private func streamApiKeyRequired(
        providerName: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let text = "💡 **Configuración requerida**: Para realizar consultas en vivo a los modelos de **\(providerName)**, abre el menú de Configuración (icono de perfil superior derecho) e ingresa tu API Key correspondiente."
        continuation.yield(text)
        continuation.finish()
    }
    
    private func streamOllamaError(
        host: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let targetHost = host.isEmpty ? "http://localhost:11434" : host
        let text = """
        ⚠️ **No se pudo conectar al servidor Ollama** (\(targetHost)).
        
        Para conectar la app a tu servidor local de Ollama:
        1. Asegúrate de tener **Ollama** ejecutándose en tu Mac o equipo de red local (`ollama serve`).
        2. Si ejecutas en un simulador o dispositivo físico en Wi-Fi, configura la IP de tu Mac en **Configuración** (ej. `http://192.168.1.50:11434`).
        3. En tu Mac, permite conexiones externas iniciando Ollama con: `OLLAMA_HOST=0.0.0.0 ollama serve`.
        """
        continuation.yield(text)
        continuation.finish()
    }
    
    // MARK: - Simulated Response (Offline Demo Mode)
    private func streamSimulated(
        model: LLMModel,
        prompt: String,
        contextFiles: [ContextFile],
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let activeFiles = contextFiles.filter { $0.isInContext }
        let responseText = """
        ¡Hola! Soy **\(model.name)** (\(model.engineLabel)).
        
        Para ayudarte a construir tu **API en Python**, la mejor alternativa moderna es usar **FastAPI** junto con **Uvicorn**.

        Aquí tienes la guía de implementación paso a paso:

        ### 1. Instalación de dependencias
        ```bash
        pip install fastapi uvicorn pydantic
        ```

        ### 2. Estructura básica de la API (`main.py`)
        ```python
        from fastapi import FastAPI
        from pydantic import BaseModel

        app = FastAPI(title="ManyLLM API", version="1.0.0")

        class Item(BaseModel):
            name: str
            description: str | None = None
            price: float

        @app.get("/")
        def read_root():
            return {"message": "¡API en Python ejecutándose correctamente!"}

        @app.post("/items/")
        def create_item(item: Item):
            return {"status": "created", "item": item}
        ```

        ### 3. Ejecutar el servidor de desarrollo
        ```bash
        uvicorn main:app --reload --host 0.0.0.0 --port 8000
        ```

        Abre tu navegador en `http://localhost:8000/docs` para ver la documentación interactiva Swagger generada automáticamente.

        *(Nota: Si deseas conectar modelos en tiempo real con Ollama o APIs de la nube, configura tu Host/API Keys en el menú de Configuración).*
        """
        
        let words = responseText.components(separatedBy: " ")
        for word in words {
            try await Task.sleep(nanoseconds: 30_000_000)
            continuation.yield(word + " ")
        }
        continuation.finish()
    }
}
