//
//  SidebarView.swift
//  many-llms
//

import SwiftUI

public struct SidebarView: View {
    @ObservedObject var store: WorkspaceStore
    @State private var showingNewWorkspaceAlert = false
    @State private var newWorkspaceName = ""
    
    public init(store: WorkspaceStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Workspaces")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Workspaces Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Workspaces")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
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
                        .padding(.horizontal, 16)
                        
                        VStack(spacing: 4) {
                            ForEach(store.workspaces) { ws in
                                Button(action: {
                                    store.selectWorkspace(ws)
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: ws.isActive ? "folder.fill" : "folder")
                                            .foregroundColor(ws.isActive ? .primary : .secondary)
                                        
                                        Text(ws.name)
                                            .font(.subheadline)
                                            .fontWeight(ws.isActive ? .semibold : .regular)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if ws.isActive {
                                            Text("Active")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.primary.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(ws.isActive ? Color.gray.opacity(0.15) : Color.clear)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Files Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Files")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        VStack(spacing: 6) {
                            ForEach(store.contextFiles) { file in
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        Text(store.activeFilesCountText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .frame(minWidth: 240, maxWidth: 280)
        .background(Color(UIColor.systemGroupedBackground))
        .alert("New Workspace", isPresented: $showingNewWorkspaceAlert) {
            TextField("Workspace Name", text: $newWorkspaceName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                store.addWorkspace(name: newWorkspaceName)
            }
        } message: {
            Text("Enter a name for your new chat workspace.")
        }
    }
}
