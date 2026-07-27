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

// MARK: - Formatted Chat Bubble & Code Block View
public struct ManyLLMChatBubbleView: View {
    public let message: ChatMessage
    
    public init(message: ChatMessage) {
        self.message = message
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer()
                
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(20)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if let modelName = message.modelName {
                        Text(modelName)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    if message.content.isEmpty {
                        Text("Pensando...")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                    } else {
                        MessageContentFormattedView(content: message.content)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Markdown & Code Block Formatter Component
struct MessageContentFormattedView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let blocks = parseContentBlocks(content)
            ForEach(0..<blocks.count, id: \.self) { idx in
                let block = blocks[idx]
                if block.isCode {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(block.language.isEmpty ? "code" : block.language)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = block.text
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copiar")
                                }
                                .font(.caption2)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        Text(block.text)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Color.green)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 24/255, green: 28/255, blue: 36/255))
                            .cornerRadius(8)
                    }
                    .padding(10)
                    .background(Color(red: 18/255, green: 20/255, blue: 26/255))
                    .cornerRadius(12)
                } else {
                    Text(LocalizedStringKey(block.text))
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
    
    struct ContentBlock {
        let isCode: Bool
        let language: String
        let text: String
    }
    
    private func parseContentBlocks(_ rawText: String) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        let parts = rawText.components(separatedBy: "```")
        
        for (index, part) in parts.enumerated() {
            if index % 2 == 1 {
                var lines = part.components(separatedBy: "\n")
                let lang = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !lines.isEmpty { lines.removeFirst() }
                let codeText = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                blocks.append(ContentBlock(isCode: true, language: lang, text: codeText.isEmpty ? part : codeText))
            } else {
                let text = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    blocks.append(ContentBlock(isCode: false, language: "", text: text))
                }
            }
        }
        
        return blocks.isEmpty ? [ContentBlock(isCode: false, language: "", text: rawText)] : blocks
    }
}
