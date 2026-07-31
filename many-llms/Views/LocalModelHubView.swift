//
//  LocalModelHubView.swift
//  many-llms
//  v1.2 Feature - Local Model Hub & LM Studio Manager
//

import SwiftUI
import Combine

public struct LocalModelHubView: View {
    @StateObject private var downloadService = ModelDownloadService.shared
    @StateObject private var hardwareGuard = HardwareGuardService.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Hardware & Safety Banner
                        hardwareBannerView
                        
                        // Curated GGUF Models List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Modelos Locales Disponibles")
                                    .font(.headline)
                                Spacer()
                                Text("Formato GGUF / MLX")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)
                            
                            ForEach(downloadService.localModels) { model in
                                modelCardRow(model)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("LM Studio Mobile Hub")
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
    
    private var hardwareBannerView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "cpu.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(hardwareGuard.deviceModelName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("RAM límite para App: \(hardwareGuard.formattedRAMLimit) / \(hardwareGuard.formattedTotalRAM)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: hardwareGuard.thermalRiskLevel.icon)
                    Text(hardwareGuard.thermalRiskLevel.rawValue)
                }
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
    
    private func modelCardRow(_ model: LocalModelInfo) -> some View {
        let safety = hardwareGuard.canRunModelSafely(model)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(model.name)
                            .font(.headline)
                        
                        Text(model.parameterCount)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                        
                        Text(model.quantization)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(6)
                    }
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            
            HStack {
                Label("\(model.formattedFileSize)", systemImage: "internaldrive")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Label("RAM: \(model.formattedRAMRequired)", systemImage: "memorychip")
                    .font(.caption2)
                    .foregroundColor(safety.canRun ? .secondary : .orange)
                
                Spacer()
                
                actionButtonForModel(model)
            }
            
            if let warning = safety.warningMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(warning)
                }
                .font(.caption2)
                .foregroundColor(.orange)
                .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
    
    @ViewBuilder
    private func actionButtonForModel(_ model: LocalModelInfo) -> some View {
        switch model.state {
        case .notDownloaded, .failed:
            Button {
                downloadService.downloadModel(model)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Descargar")
                }
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
        case .downloading(let progress, let speed):
            VStack(alignment: .trailing, spacing: 2) {
                ProgressView(value: progress)
                    .frame(width: 80)
                Text(String(format: "%.0f%% (%.1f MB/s)", progress * 100, speed))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
        case .ready:
            HStack(spacing: 8) {
                Label("Descargado", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Button {
                    downloadService.deleteModel(model)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}
