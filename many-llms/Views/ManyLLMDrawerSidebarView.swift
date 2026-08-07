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
    @State private var showingAddFileAlert = false
    @State private var newFileName = ""
    @State private var newFileContent = ""
    
    public init(store: WorkspaceStore, isDrawerOpen: Binding<Bool>) {
        self.store = store
        self._isDrawerOpen = isDrawerOpen
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                    Text("ManyLLM")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    store.isSettingsPresented = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDrawerOpen = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 14)
            
            Divider()
            
            // Content List
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Section: Workspaces / Projects
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(store.loc("section_workspaces").uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                newWorkspaceName = ""
                                showingNewWorkspaceAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .bold))
                                    Text(store.appLanguage == .en ? "New" : "Nuevo")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 18)
                        
                        VStack(spacing: 4) {
                            ForEach(store.workspaces) { ws in
                                Button(action: {
                                    store.selectWorkspace(ws)
                                    withAnimation { isDrawerOpen = false }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: ws.isActive ? "folder.fill" : "folder")
                                            .font(.system(size: 16))
                                            .foregroundColor(ws.isActive ? .blue : .secondary)
                                        
                                        Text(ws.name)
                                            .font(.system(size: 15, weight: ws.isActive ? .semibold : .regular))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        if ws.isActive {
                                            Text(store.loc("badge_active"))
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(ws.isActive ? Color.blue.opacity(0.1) : Color.clear)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    Divider().padding(.horizontal, 18)
                    
                    // Section: Archivos de Contexto
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(store.loc("section_context_files").uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                newFileName = ""
                                newFileContent = ""
                                showingAddFileAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 12, weight: .bold))
                                    Text(store.appLanguage == .en ? "Add" : "Agregar")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 18)
                        
                        VStack(spacing: 6) {
                            ForEach(store.contextFiles) { file in
                                HStack(spacing: 12) {
                                    Image(systemName: file.fileType == "pdf" ? "doc.richtext" : "doc.text")
                                        .font(.system(size: 16))
                                        .foregroundColor(file.isInContext ? .blue : .secondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Text(file.sizeText)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        store.toggleContextFile(file)
                                    }) {
                                        Image(systemName: file.isInContext ? "eye.fill" : "eye.slash")
                                            .font(.system(size: 14))
                                            .foregroundColor(file.isInContext ? .blue : Color.gray.opacity(0.6))
                                            .padding(6)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 10)
                        
                        Text(store.activeFilesCountText)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 18)
                    }
                }
                .padding(.vertical, 16)
            }
            
            Divider()
            
            // Bottom Sticky Bar (Profile Avatar + New Chat Floating Button)
            HStack(spacing: 12) {
                // Settings Profile Avatar
                Button(action: {
                    store.isSettingsPresented = true
                }) {
                    HStack(spacing: 8) {
                        Text("ML")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.18))
                            .clipShape(Circle())
                        
                        Text(store.loc("settings_title"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // + Nuevo Chat Pill Button
                Button(action: {
                    store.clearChatHistory()
                    store.inputPrompt = ""
                    withAnimation { isDrawerOpen = false }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text(store.loc("btn_new_chat"))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
        }
        .frame(maxWidth: 320)
        .background(Color(UIColor.systemBackground))
        .alert("Nuevo Workspace", isPresented: $showingNewWorkspaceAlert) {
            TextField("Nombre del Workspace", text: $newWorkspaceName)
            Button(store.loc("cancel"), role: .cancel) { }
            Button("OK") {
                store.addWorkspace(name: newWorkspaceName)
            }
        }
        .alert("Agregar Archivo de Contexto", isPresented: $showingAddFileAlert) {
            TextField("Nombre del archivo (ej. notas.txt)", text: $newFileName)
            TextField("Contenido del archivo", text: $newFileContent)
            Button(store.loc("cancel"), role: .cancel) { }
            Button("Agregar") {
                if !newFileName.isEmpty {
                    store.addCustomContextFile(name: newFileName, content: newFileContent)
                }
            }
        }
    }
}
