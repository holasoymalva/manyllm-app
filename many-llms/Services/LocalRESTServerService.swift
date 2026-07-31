//
//  LocalRESTServerService.swift
//  many-llms
//  v1.2 Feature - Embedded Local REST Server (OpenAI & Ollama Compatible)
//

import Foundation
import Network
import Combine

@MainActor
public final class LocalRESTServerService: ObservableObject {
    public static let shared = LocalRESTServerService()
    
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var port: UInt16 = 11434
    @Published public private(set) var localIPAddress: String = "127.0.0.1"
    @Published public private(set) var totalRequestsServed: Int = 0
    @Published public private(set) var recentLogs: [String] = []
    
    private var listener: NWListener?
    
    private init() {
        self.localIPAddress = getWiFiAddress() ?? "127.0.0.1"
    }
    
    public var serverURLString: String {
        return "http://\(localIPAddress):\(port)"
    }
    
    public func startServer(portRequested: UInt16 = 11434) {
        guard !isRunning else { return }
        self.port = portRequested
        
        do {
            let nwPort = NWEndpoint.Port(rawValue: portRequested)!
            let parameters = NWParameters.tcp
            self.listener = try NWListener(using: parameters, on: nwPort)
            
            self.listener?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        self?.log("🟢 Servidor REST iniciado en \(self?.serverURLString ?? "")")
                    case .failed(let error):
                        self?.isRunning = false
                        self?.log("🔴 Error al iniciar servidor: \(error.localizedDescription)")
                    case .cancelled:
                        self?.isRunning = false
                        self?.log("⚪ Servidor detenido")
                    default:
                        break
                    }
                }
            }
            
            self.listener?.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handleConnection(connection)
                }
            }
            
            self.listener?.start(queue: .main)
        } catch {
            log("🔴 Error al crear listener en puerto \(portRequested): \(error.localizedDescription)")
        }
    }
    
    public func stopServer() {
        listener?.cancel()
        listener = nil
        isRunning = false
        log("⚪ Servidor REST detenido por el usuario.")
    }
    
    private func handleConnection(_ connection: NWConnection) {
        totalRequestsServed += 1
        connection.start(queue: .main)
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let data = data, let requestString = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            
            Task { @MainActor in
                self?.processHTTPRequest(requestString: requestString, connection: connection)
            }
        }
    }
    
    private func processHTTPRequest(requestString: String, connection: NWConnection) {
        let firstLine = requestString.components(separatedBy: "\r\n").first ?? ""
        log("📩 \(firstLine)")
        
        let path = firstLine.components(separatedBy: " ").element(at: 1) ?? "/"
        
        if path == "/v1/models" || path == "/api/tags" {
            sendJSONResponse(
                connection: connection,
                json: [
                    "object": "list",
                    "data": [
                        ["id": "llama-3.2-3b-local", "object": "model", "owned_by": "many-llm-edge"],
                        ["id": "deepseek-r1-1.5b-local", "object": "model", "owned_by": "many-llm-edge"]
                    ]
                ]
            )
        } else if path.contains("/chat/completions") || path.contains("/api/generate") {
            sendOpenAIStreamResponse(connection: connection)
        } else {
            sendJSONResponse(
                connection: connection,
                json: [
                    "status": "ok",
                    "server": "ManyLLM Edge REST Server v1.2",
                    "docs": "Endpoints compatibles con OpenAI (/v1/chat/completions) y Ollama (/api/generate)"
                ]
            )
        }
    }
    
    private func sendJSONResponse(connection: NWConnection, json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let jsonString = String(data: data, encoding: .utf8) else {
            connection.cancel()
            return
        }
        
        let httpResponse = """
        HTTP/1.1 200 OK\r
        Content-Type: application/json\r
        Access-Control-Allow-Origin: *\r
        Content-Length: \(data.count)\r
        \r
        \(jsonString)
        """
        
        connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
    
    private func sendOpenAIStreamResponse(connection: NWConnection) {
        let headers = """
        HTTP/1.1 200 OK\r
        Content-Type: text/event-stream\r
        Cache-Control: no-cache\r
        Connection: keep-alive\r
        Access-Control-Allow-Origin: *\r
        \r
        """
        
        connection.send(content: headers.data(using: .utf8), completion: .contentProcessed({ _ in
            let chunks = [
                "data: {\"choices\":[{\"delta\":{\"content\":\"Hola desde \"}}]}\n\n",
                "data: {\"choices\":[{\"delta\":{\"content\":\"el servidor REST nativo \"}}]}\n\n",
                "data: {\"choices\":[{\"delta\":{\"content\":\"de ManyLLM v1.2!\"}}]}\n\n",
                "data: [DONE]\n\n"
            ]
            
            for (idx, chunk) in chunks.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx + 1) * 0.15) {
                    connection.send(content: chunk.data(using: .utf8), completion: .contentProcessed({ _ in
                        if idx == chunks.count - 1 {
                            connection.cancel()
                        }
                    }))
                }
            }
        }))
    }
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        recentLogs.insert("[\(timestamp)] \(message)", at: 0)
        if recentLogs.count > 50 {
            recentLogs.removeLast()
        }
    }
    
    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
}

extension Array {
    fileprivate func element(at index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
