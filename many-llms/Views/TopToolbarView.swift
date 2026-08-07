//
//  TopToolbarView.swift
//  many-llms
//

import SwiftUI

public struct TopToolbarView: View {
    @ObservedObject var store: WorkspaceStore
    
    public init(store: WorkspaceStore) {
        self.store = store
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Model Selector Dropdown
            Menu {
                ForEach(store.availableModels) { model in
                    Button(action: {
                        store.selectedModel = model
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.name)
                                    .fontWeight(store.selectedModel.id == model.id ? .bold : .regular)
                                Text(model.engineLabel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if store.selectedModel.id == model.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.selectedModel.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        Text(store.selectedModel.engineLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
            }
            
            // Temp Slider
            HStack(spacing: 6) {
                Text("Temp:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Slider(value: $store.parameters.temperature, in: 0.0...1.0, step: 0.05)
                    .frame(width: 80)
                    .accentColor(.blue)
                
                Text(String(format: "%.1f", store.parameters.temperature))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 32, alignment: .leading)
            }
            
            // Max Tokens Slider
            HStack(spacing: 6) {
                Text("Max:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { Double(store.parameters.maxTokens) },
                    set: { store.parameters.maxTokens = Int($0) }
                ), in: 250...4000, step: 250)
                .frame(width: 80)
                .accentColor(.blue)
                
                Text("\(store.parameters.maxTokens)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 44, alignment: .leading)
            }
            
            Spacer()
            
            // Settings & Start Button
            HStack(spacing: 10) {
                Button(action: {
                    store.isSettingsPresented = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.subheadline)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    Task {
                        await store.checkOllamaConnection()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                        Text(store.isOllamaConnected ? "Conectado" : "Conectar")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(store.isOllamaConnected ? Color.green : Color.blue)
                    .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.15)),
            alignment: .bottom
        )
    }
}
