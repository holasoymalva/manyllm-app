//
//  ChatAreaView.swift
//  many-llms
//

import SwiftUI

public struct ChatAreaView: View {
    @ObservedObject var store: WorkspaceStore
    @FocusState private var isInputFocused: Bool
    
    public init(store: WorkspaceStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main Content: Empty State vs Message History
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
                    
                    VStack(spacing: 6) {
                        Text("Welcome to ManyLLM Preview")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Type a message below to start chatting with \(store.selectedModel.name).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(store.chatMessages) { msg in
                                ChatBubbleView(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 20)
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
            
            Divider()
            
            // Bottom Input Controls Area
            VStack(spacing: 8) {
                // System Prompt Accordion / Toggle Header
                HStack {
                    Button(action: {
                        withAnimation {
                            store.systemPromptExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("System Prompt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: store.systemPromptExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(store.wordCount) words • Cmd+K to focus • Cmd+Enter to send")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                if store.systemPromptExpanded {
                    TextEditor(text: $store.parameters.systemPrompt)
                        .font(.caption)
                        .frame(height: 50)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                        .padding(.horizontal, 16)
                }
                
                // Prompt Input Box & Send Button
                HStack(alignment: .bottom, spacing: 10) {
                    ZStack(alignment: .leading) {
                        if store.inputPrompt.isEmpty {
                            Text("Message \(store.selectedModel.name)...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        
                        TextEditor(text: $store.inputPrompt)
                            .font(.subheadline)
                            .frame(minHeight: 40, maxHeight: 100)
                            .focused($isInputFocused)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    Button(action: {
                        store.sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(store.inputPrompt.isEmpty || store.isGenerating ? Color.gray : Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(store.inputPrompt.isEmpty || store.isGenerating)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(Color(UIColor.systemBackground))
        }
    }
}

public struct ChatBubbleView: View {
    public let message: ChatMessage
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
            } else {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .padding(8)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    if let modelName = message.modelName {
                        Text(modelName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(message.content.isEmpty ? "Thinking..." : message.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                }
                
                Spacer()
            }
        }
    }
}
