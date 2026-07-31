//
//  ModelDownloadService.swift
//  many-llms
//  v1.2 Feature - Model Downloader & Hub Service
//

import Foundation
import Combine

@MainActor
public final class ModelDownloadService: NSObject, ObservableObject {
    public static let shared = ModelDownloadService()
    
    @Published public private(set) var localModels: [LocalModelInfo] = []
    @Published public private(set) var activeDownloads: [String: Double] = [:] // modelId -> progress 0..1
    @Published public private(set) var downloadSpeeds: [String: Double] = [:] // modelId -> speed MB/s
    
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var downloadStartTimes: [String: Date] = [:]
    private var session: URLSession!
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.isDiscretionary = false
        self.session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        
        loadLocalModelsState()
    }
    
    public var modelsDirectoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelsDir = docs.appendingPathComponent("LocalModels", isDirectory: true)
        if !FileManager.default.fileExists(atPath: modelsDir.path) {
            try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
        return modelsDir
    }
    
    public func getLocalFilePath(for model: LocalModelInfo) -> URL {
        return modelsDirectoryURL.appendingPathComponent(model.fileName)
    }
    
    public func loadLocalModelsState() {
        var presets = LocalModelInfo.presetLocalModels
        
        for index in presets.indices {
            let model = presets[index]
            let fileURL = getLocalFilePath(for: model)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                presets[index].state = .ready(filePath: fileURL.path)
            } else {
                presets[index].state = .notDownloaded
            }
        }
        
        self.localModels = presets
    }
    
    public func downloadModel(_ model: LocalModelInfo) {
        guard downloadTasks[model.id] == nil else { return }
        guard let url = URL(string: model.downloadURLString) else { return }
        
        if let index = localModels.firstIndex(where: { $0.id == model.id }) {
            localModels[index].state = .downloading(progress: 0.0, speedMBps: 0.0)
        }
        
        activeDownloads[model.id] = 0.0
        downloadStartTimes[model.id] = Date()
        
        let destinationURL = getLocalFilePath(for: model)
        
        Task {
            do {
                let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                let expectedLength = response.expectedContentLength
                var downloadedBytes: Int64 = 0
                let startTime = Date()
                
                var data = Data()
                // Stream write to disk
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try? fileManager.removeItem(at: destinationURL)
                }
                fileManager.createFile(atPath: destinationURL.path, contents: nil)
                let fileHandle = try FileHandle(forWritingTo: destinationURL)
                
                var buffer = Data()
                let bufferSize = 1_048_576 // 1MB buffer
                
                for try await byte in asyncBytes {
                    buffer.append(byte)
                    downloadedBytes += 1
                    
                    if buffer.count >= bufferSize {
                        fileHandle.write(buffer)
                        buffer.removeAll(keepingCapacity: true)
                        
                        let progress = expectedLength > 0 ? Double(downloadedBytes) / Double(expectedLength) : 0.5
                        let elapsedTime = Date().timeIntervalSince(startTime)
                        let speedMBps = elapsedTime > 0 ? (Double(downloadedBytes) / 1_048_576.0) / elapsedTime : 0.0
                        
                        self.activeDownloads[model.id] = progress
                        self.downloadSpeeds[model.id] = speedMBps
                        
                        if let idx = self.localModels.firstIndex(where: { $0.id == model.id }) {
                            self.localModels[idx].state = .downloading(progress: progress, speedMBps: speedMBps)
                        }
                    }
                }
                
                if !buffer.isEmpty {
                    fileHandle.write(buffer)
                }
                try fileHandle.close()
                
                self.activeDownloads.removeValue(forKey: model.id)
                self.downloadSpeeds.removeValue(forKey: model.id)
                
                if let idx = self.localModels.firstIndex(where: { $0.id == model.id }) {
                    self.localModels[idx].state = .ready(filePath: destinationURL.path)
                }
                
            } catch {
                self.activeDownloads.removeValue(forKey: model.id)
                self.downloadSpeeds.removeValue(forKey: model.id)
                
                if let idx = self.localModels.firstIndex(where: { $0.id == model.id }) {
                    self.localModels[idx].state = .failed(error: error.localizedDescription)
                }
            }
        }
    }
    
    public func deleteModel(_ model: LocalModelInfo) {
        let fileURL = getLocalFilePath(for: model)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        if let index = localModels.firstIndex(where: { $0.id == model.id }) {
            localModels[index].state = .notDownloaded
        }
    }
}
