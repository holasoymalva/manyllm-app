//
//  MultiModelArenaView.swift
//  many-llms
//  v1.2 Feature - Multi-Model Arena & Prompt Comparison Playground
//

import SwiftUI
import Combine

public struct MultiModelArenaView: View {
    @EnvironmentObject private var workspaceStore: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var arenaPrompt: String = "Explica en 3 puntos la diferencia entre un modelo cuantitativo Q4_K_M y Q8_0."
    @State private var modelA: LLMModel = LLMModel.presetModels[2] // Qwen 7B / Local
    @State private var modelB: LLMModel = LLMModel.presetModels[4] // GPT-4o / Cloud
    
    @State private var responseA: String = ""
    @State private var responseB: String = ""
    
    @State private var isRunningA: Bool = false
    @State private var isRunningB: Bool = false
    
    @State private var tpsA: Double = 0.0
    @State private var tpsB: Double = 0.0
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Prompt Input Box
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt de Comparación")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Ingresa un prompt para evaluar ambos modelos...", text: $arenaPrompt)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            runArenaComparison()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Evaluar")
                            }
                            .fontWeight(.bold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(arenaPrompt.isEmpty || isRunningA || isRunningB)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(14)
                
                // Arena Side-by-Side Comparison
                HStack(spacing: 12) {
                    // Model A Panel
                    arenaModelColumn(
                        title: "Modelo A",
                        model: $modelA,
                        response: responseA,
                        isRunning: isRunningA,
                        tps: tpsA
                    )
                    
                    // Model B Panel
                    arenaModelColumn(
                        title: "Modelo B",
                        model: $modelB,
                        response: responseB,
                        isRunning: isRunningB,
                        tps: tpsB
                    )
                }
            }
            .padding()
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Multi-Model Arena")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func arenaModelColumn(
        title: String,
        model: Binding<LLMModel>,
        response: String,
        isRunning: Bool,
        tps: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if tps > 0 {
                    Text(String(format: "%.1f TPS", tps))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            Picker("Modelo", selection: model) {
                ForEach(workspaceStore.availableModels) { item in
                    Text(item.name).tag(item)
                }
            }
            .pickerStyle(.menu)
            
            ScrollView {
                Text(response.isEmpty ? "Las respuestas generadas aparecerán aquí..." : response)
                    .font(.subheadline)
                    .foregroundColor(response.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(10)
        }
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
    
    private func runArenaComparison() {
        guard !arenaPrompt.isEmpty else { return }
        
        responseA = ""
        responseB = ""
        isRunningA = true
        isRunningB = true
        tpsA = 0.0
        tpsB = 0.0
        
        // Execute Model A
        Task {
            let streamA = LLMService.shared.streamCompletion(
                model: modelA,
                prompt: arenaPrompt,
                messages: [],
                contextFiles: workspaceStore.contextFiles,
                parameters: workspaceStore.parameters,
                ollamaHost: workspaceStore.ollamaHost,
                openAIKey: workspaceStore.openAIKey,
                anthropicKey: workspaceStore.anthropicKey,
                huggingFaceToken: workspaceStore.huggingFaceToken,
                customEndpoint: workspaceStore.customEndpoint
            )
            
            let start = Date()
            var count = 0
            do {
                for try await chunk in streamA {
                    responseA += chunk
                    count += 1
                    let elapsed = Date().timeIntervalSince(start)
                    tpsA = elapsed > 0 ? Double(count) / elapsed : 0
                }
            } catch {
                responseA += "\n[Error: \(error.localizedDescription)]"
            }
            isRunningA = false
        }
        
        // Execute Model B
        Task {
            let streamB = LLMService.shared.streamCompletion(
                model: modelB,
                prompt: arenaPrompt,
                messages: [],
                contextFiles: workspaceStore.contextFiles,
                parameters: workspaceStore.parameters,
                ollamaHost: workspaceStore.ollamaHost,
                openAIKey: workspaceStore.openAIKey,
                anthropicKey: workspaceStore.anthropicKey,
                huggingFaceToken: workspaceStore.huggingFaceToken,
                customEndpoint: workspaceStore.customEndpoint
            )
            
            let start = Date()
            var count = 0
            do {
                for try await chunk in streamB {
                    responseB += chunk
                    count += 1
                    let elapsed = Date().timeIntervalSince(start)
                    tpsB = elapsed > 0 ? Double(count) / elapsed : 0
                }
            } catch {
                responseB += "\n[Error: \(error.localizedDescription)]"
            }
            isRunningB = false
        }
    }
}
