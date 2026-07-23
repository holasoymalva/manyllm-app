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
                        // Generic Account Card (No Personal Data!)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cuenta ManyLLM")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Versión MVP Local & Remota")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        // Promo / Features Card
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            Text("Ejecuta modelos sin límites")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        // Section: Ollama Host & Connection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Servidor Ollama")
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
                                    Text("Estado")
                                        .font(.subheadline)
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text("Disponible")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(14)
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        
                        // Section: API Keys
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
                        
                        // Section: Aspecto
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Aspecto")
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
                            store.chatMessages.removeAll()
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
                    Text("Configuración")
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
                    
                    // Inner miniature card lines
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

