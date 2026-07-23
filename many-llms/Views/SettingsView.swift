//
//  SettingsView.swift
//  many-llms
//

import SwiftUI

public struct SettingsView: View {
    @ObservedObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    
    public init(store: WorkspaceStore) {
        self.store = store
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ollama Local / Network Server")) {
                    HStack {
                        Text("Host URL")
                        Spacer()
                        TextField("http://localhost:11434", text: $store.ollamaHost)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    Text("Connect to your local Ollama instance or remote Ollama server on your Wi-Fi network.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Cloud LLM API Keys")) {
                    SecureField("OpenAI API Key (sk-...)", text: $store.openAIKey)
                        .autocapitalization(.none)
                    
                    SecureField("Anthropic API Key (sk-ant-...)", text: $store.anthropicKey)
                        .autocapitalization(.none)
                    
                    SecureField("HuggingFace User Token (hf_...)", text: $store.huggingFaceToken)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Default Prompt Settings")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Prompt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $store.parameters.systemPrompt)
                            .frame(height: 80)
                    }
                }
                
                Section(header: Text("About Many LLMs")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Execution Engine")
                        Spacer()
                        Text("Swift REST + Local Stub")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
