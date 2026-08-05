//
//  ManyLLMSettingsView.swift
//  many-llms
//

import SwiftUI

public enum AppTheme: String, CaseIterable, Identifiable {
    case light = "Claro"
    case dark = "Oscuro"
    case system = "Sistema"
    
    public var id: String { rawValue }
}

public struct ManyLLMSettingsView: View {
    @ObservedObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var hapticFeedbackEnabled: Bool = true
    @State private var selectedTheme: AppTheme = .light
    
    @State private var isLocalHubPresented: Bool = false
    @State private var isLocalServerPresented: Bool = false
    @State private var isArenaPresented: Bool = false
    
    public init(store: WorkspaceStore) {
        self.store = store
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Section: v1.2 Dev Tools & Edge Engine
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Herramientas de Desarrollador v1.2")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                Button {
                                    isLocalHubPresented = true
                                } label: {
                                    HStack {
                                        Image(systemName: "cpu.fill")
                                            .foregroundColor(.accentColor)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("LM Studio Mobile Hub")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text("Descarga y gestiona modelos GGUF/MLX on-device")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(14)
                                }
                                .sheet(isPresented: $isLocalHubPresented) {
                                    LocalModelHubView()
                                }
                                
                                Divider().padding(.leading, 44)
                                
                                Button {
                                    isLocalServerPresented = true
                                } label: {
                                    HStack {
                                        Image(systemName: "network")
                                            .foregroundColor(.green)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Servidor REST Local (Ollama/OpenAI)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text("Transforma tu iPhone/iPad en un nodo API local")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(14)
                                }
                                .sheet(isPresented: $isLocalServerPresented) {
                                    LocalRESTServerView()
                                }
                                
                                Divider().padding(.leading, 44)
                                
                                Button {
                                    isArenaPresented = true
                                } label: {
                                    HStack {
                                        Image(systemName: "speedometer")
                                            .foregroundColor(.purple)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Multi-Model Arena")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text("Compara 2 modelos side-by-side con TPS y TTFT")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(14)
                                }
                                .sheet(isPresented: $isArenaPresented) {
                                    MultiModelArenaView()
                                        .environmentObject(store)
                                }
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        
                        // Generic Account Card
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cuenta ManyLLM")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Versión 1.2 (Edge AI Node)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        // Section: Ollama Host & Live Connection Test
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Servidor Ollama (Red Local)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Host URL")
                                        .font(.subheadline)
                                    Spacer()
                                    TextField("http://localhost:11434", text: $store.ollamaHost)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.trailing)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(14)
                                
                                Divider().padding(.leading, 14)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Estado")
                                            .font(.subheadline)
                                        Text(store.ollamaStatusMessage)
                                            .font(.caption2)
                                            .foregroundColor(store.isOllamaConnected ? .green : .red)
                                    }
                                    Spacer()
                                    
                                    Button(action: {
                                        Task {
                                            await store.checkOllamaConnection()
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            if store.isTestingConnection {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "network")
                                            }
                                            Text("Probar Conexión")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                    }
                                    .disabled(store.isTestingConnection)
                                }
                                .padding(14)
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        
                        // Section: Custom OpenAI-Compatible Endpoint (LM Studio, OpenRouter, vLLM)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Servidor OpenAI-Compatible Personalizado")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Base URL")
                                        .font(.subheadline)
                                    Spacer()
                                    TextField("http://192.168.1.X:1234/v1", text: $store.customEndpoint)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.trailing)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(14)
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        
                        // Section: API Keys Remotas
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Claves de API Remotas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "key")
                                        .foregroundColor(.secondary)
                                    SecureField("OpenAI API Key (sk-...)", text: $store.openAIKey)
                                        .font(.subheadline)
                                        .autocapitalization(.none)
                                }
                                .padding(14)
                                
                                Divider().padding(.leading, 14)
                                
                                HStack {
                                    Image(systemName: "key")
                                        .foregroundColor(.secondary)
                                    SecureField("Anthropic API Key (sk-ant-...)", text: $store.anthropicKey)
                                        .font(.subheadline)
                                        .autocapitalization(.none)
                                }
                                .padding(14)
                                
                                Divider().padding(.leading, 14)
                                
                                HStack {
                                    Image(systemName: "key")
                                        .foregroundColor(.secondary)
                                    SecureField("HuggingFace User Token (hf_...)", text: $store.huggingFaceToken)
                                        .font(.subheadline)
                                        .autocapitalization(.none)
                                }
                                .padding(14)
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        
                        // Section: App Settings
                        VStack(alignment: .leading, spacing: 10) {
                            Text("App")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                SettingsRowView(icon: "slider.horizontal.3", title: "Capacidades")
                                Divider().padding(.leading, 44)
                                SettingsRowView(icon: "square.grid.2x2", title: "Conectores")
                                Divider().padding(.leading, 44)
                                SettingsRowView(icon: "lock.shield", title: "Permisos")
                                Divider().padding(.leading, 44)
                                SettingsRowView(icon: "waveform", title: "Voz")
                                Divider().padding(.leading, 44)
                                
                                HStack {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    Text("Retroalimentación háptica")
                                        .font(.subheadline)
                                    Spacer()
                                    Toggle("", isOn: $hapticFeedbackEnabled)
                                        .labelsHidden()
                                }
                                .padding(14)
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        
                        // Section: Idioma / Language
                        VStack(alignment: .leading, spacing: 10) {
                            Text(store.loc("settings_language"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Button(action: {
                                        store.appLanguage = lang
                                    }) {
                                        HStack {
                                            Text(lang.displayName)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if store.appLanguage == lang {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                                    .font(.subheadline)
                                            }
                                        }
                                        .padding(14)
                                    }
                                    if lang != AppLanguage.allCases.last {
                                        Divider().padding(.leading, 14)
                                    }
                                }
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        
                        // Section: Aspecto
                        VStack(alignment: .leading, spacing: 10) {
                            Text(store.loc("settings_theme"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            HStack(spacing: 12) {
                                ThemeCardView(theme: .light, isSelected: selectedTheme == .light) {
                                    selectedTheme = .light
                                }
                                ThemeCardView(theme: .dark, isSelected: selectedTheme == .dark) {
                                    selectedTheme = .dark
                                }
                                ThemeCardView(theme: .system, isSelected: selectedTheme == .system) {
                                    selectedTheme = .system
                                }
                            }
                        }
                        
                        // Section: Reset / Logout
                        Button(action: {
                            store.clearChatHistory()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Limpiar historial de chats")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(store.loc("settings_title"))
                        .font(.system(size: 17, weight: .bold))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { }) {
                        Image(systemName: "info")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
    }
}

struct ThemeCardView: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme == .dark ? Color.black : (theme == .light ? Color.white : Color.gray.opacity(0.3)))
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                            .frame(width: 36, height: 4)
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Text(theme.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
