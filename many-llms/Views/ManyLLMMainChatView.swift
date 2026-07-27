//
//  ManyLLMMainChatView.swift
//  many-llms
//

import SwiftUI
import UniformTypeIdentifiers

public struct ManyLLMMainChatView: View {
    @ObservedObject var store: WorkspaceStore
    @Binding var isDrawerOpen: Bool
    @FocusState private var isInputFocused: Bool
    @State private var showingFileImporter = false
    @State private var showingFileImportAlert = false
    @State private var importedFileName = ""
    
    public init(store: WorkspaceStore, isDrawerOpen: Binding<Bool>) {
        self.store = store
        self._isDrawerOpen = isDrawerOpen
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Bar Header
            HStack {
                // Circular Hamburger Menu Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isDrawerOpen.toggle()
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                }
                
                Spacer()
                
                // Connection Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(store.isOllamaConnected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(store.isOllamaConnected ? "Ollama Activo" : "Red Local")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                
                Spacer()
                
                // Circular Profile / Settings Button
                Button(action: {
                    store.isSettingsPresented = true
                }) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Main Central View (Empty State vs Active Chat)
            if store.chatMessages.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    #if os(iOS)
                    GIFView(urlString: "https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExdHdwbnlzZTNiYTVnbGl4eTZlZjFueG90NjhjdWIyN2Z2dzZwNmxxYiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/w5WFZZMK1jZ2rZTHpg/giphy.gif")
                        .frame(width: 64, height: 64)
                    #else
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    #endif
                    
                    Text("Bienvenido a ManyLLM")
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 35/255, green: 30/255, blue: 30/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Text("Selecciona un modelo e ingresa tu consulta para comenzar.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(store.chatMessages) { msg in
                                ManyLLMChatBubbleView(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: store.chatMessages.count) { _, _ in
                        if let lastId = store.chatMessages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Floating Bottom Input Card
            VStack(alignment: .leading, spacing: 12) {
                // System Prompt Accordion
                if store.systemPromptExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Prompt")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextEditor(text: $store.parameters.systemPrompt)
                            .font(.caption)
                            .frame(height: 50)
                            .background(Color.clear)
                            .onChange(of: store.parameters.systemPrompt) { _, newValue in
                                store.updateParameters(temp: store.parameters.temperature, maxTok: store.parameters.maxTokens, prompt: newValue)
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    Divider()
                }
                
                // Prompt Input Text Area
                ZStack(alignment: .leading) {
                    if store.inputPrompt.isEmpty {
                        Text("Chat con \(store.selectedModel.name)")
                            .font(.system(size: 16))
                            .foregroundColor(Color.gray.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                    }
                    
                    TextEditor(text: $store.inputPrompt)
                        .font(.system(size: 16))
                        .frame(minHeight: 38, maxHeight: 110)
                        .focused($isInputFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
                
                // Bottom Control Bar Inside Card
                HStack(spacing: 10) {
                    // Attachment (+) Pill Button
                    Menu {
                        Button(action: {
                            showingFileImporter = true
                        }) {
                            Label("Importar archivo del sistema (.txt, .md, .json)", systemImage: "square.and.arrow.down")
                        }
                        
                        Divider()
                        
                        Section(header: Text("Archivos de Contexto Activos")) {
                            ForEach(store.contextFiles) { file in
                                Button(action: {
                                    store.toggleContextFile(file)
                                }) {
                                    HStack {
                                        Text(file.name)
                                        if file.isInContext {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    // Model Selector Pill Button
                    Menu {
                        ForEach(store.availableModels) { model in
                            Button(action: {
                                store.selectModel(model)
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(model.name)
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
                        HStack(spacing: 6) {
                            Text(store.selectedModel.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            Text(store.selectedModel.engineLabel)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Microphone / Send Action Button
                    Button(action: {
                        if !store.inputPrompt.isEmpty {
                            store.sendMessage()
                        }
                    }) {
                        Image(systemName: store.inputPrompt.isEmpty ? "mic.fill" : "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black)
                            .clipShape(Circle())
                    }
                    .disabled(store.isGenerating)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(UIColor.systemGroupedBackground).opacity(0.5).ignoresSafeArea())
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.plainText, .json, .sourceCode, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    if let content = try? String(contentsOf: url, encoding: .utf8) {
                        store.addCustomContextFile(name: url.lastPathComponent, content: content)
                        importedFileName = url.lastPathComponent
                        showingFileImportAlert = true
                    }
                }
            case .failure(let error):
                print("Error importing file: \(error.localizedDescription)")
            }
        }
        .alert("Archivo importado", isPresented: $showingFileImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("El archivo '\(importedFileName)' se ha añadido exitosamente al contexto de ManyLLM.")
        }
    }
}
