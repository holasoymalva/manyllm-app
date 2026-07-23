//
//  ManyLLMDrawerSidebarView.swift
//  many-llms
//

import SwiftUI

public struct ManyLLMDrawerSidebarView: View {
    @ObservedObject var store: WorkspaceStore
    @Binding var isDrawerOpen: Bool
    @State private var showingNewWorkspaceAlert = false
    @State private var newWorkspaceName = ""
    
    public init(store: WorkspaceStore, isDrawerOpen: Binding<Bool>) {
        self.store = store
        self._isDrawerOpen = isDrawerOpen
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Drawer Header
            HStack {
                Text("ManyLLM")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    store.isSettingsPresented = true
                }) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isDrawerOpen = false
                    }
                }) {
                    Image(systemName: "sidebar.leading")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Scrollable Menu Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category Links
                    VStack(alignment: .leading, spacing: 14) {
                        DrawerCategoryRow(icon: "bubble.left.and.bubble.right", title: "Chats")
                        DrawerCategoryRow(icon: "folder", title: "Proyectos")
                        DrawerCategoryRow(icon: "square.stack.3d.up", title: "Artefactos")
                        DrawerCategoryRow(icon: "chevron.left.forward.slash.chevron.right", title: "Código")
                    }
                    .padding(.horizontal, 20)
                    
                    Divider().padding(.horizontal, 20)
                    
                    // Section: Workspaces
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Workspaces")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                newWorkspaceName = ""
                                showingNewWorkspaceAlert = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 4) {
                            ForEach(store.workspaces) { ws in
                                Button(action: {
                                    store.selectWorkspace(ws)
                                    withAnimation { isDrawerOpen = false }
                                }) {
                                    HStack {
                                        Text(ws.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Image(systemName: "folder")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        if ws.isActive {
                                            Text("Active")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.15))
                                                .foregroundColor(.blue)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(ws.isActive ? Color.gray.opacity(0.12) : Color.clear)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    
                    Divider().padding(.horizontal, 20)
                    
                    // Section: Archivos de Contexto
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Archivos de Contexto")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 6) {
                            ForEach(store.contextFiles) { file in
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(file.sizeText)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        store.toggleContextFile(file)
                                    }) {
                                        Image(systemName: file.isInContext ? "eye.fill" : "eye.slash")
                                            .font(.caption)
                                            .foregroundColor(file.isInContext ? .blue : .gray)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.06))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 12)
                        
                        Text(store.activeFilesCountText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 12)
            }
            
            Spacer()
            
            // Bottom Sticky Bar (User Avatar + New Chat Floating Button)
            HStack {
                // Profile Avatar Button (opens Settings)
                Button(action: {
                    store.isSettingsPresented = true
                }) {
                    Text("ML")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.18))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // + Nuevo Chat Pill Button
                Button(action: {
                    store.chatMessages.removeAll()
                    store.inputPrompt = ""
                    withAnimation { isDrawerOpen = false }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Nuevo chat")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(UIColor.systemBackground))
        }
        .frame(maxWidth: 320)
        .background(Color(UIColor.systemBackground))
        .alert("Nuevo Workspace", isPresented: $showingNewWorkspaceAlert) {
            TextField("Nombre del Workspace", text: $newWorkspaceName)
            Button("Cancelar", role: .cancel) { }
            Button("Crear") {
                store.addWorkspace(name: newWorkspaceName)
            }
        }
    }
}

struct DrawerCategoryRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

