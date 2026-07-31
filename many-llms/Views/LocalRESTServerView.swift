//
//  LocalRESTServerView.swift
//  many-llms
//  v1.2 Feature - Local Edge Server UI & Terminal Logs
//

import SwiftUI
import Combine

public struct LocalRESTServerView: View {
    @StateObject private var server = LocalRESTServerService.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 18) {
                        // Server Status Control Card
                        serverControlCard
                        
                        // Dev Connection Instructions Card
                        devInstructionCard
                        
                        // Live Request Log Console
                        consoleLogsCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Servidor REST Local")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var serverControlCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(server.isRunning ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(server.isRunning ? "Servidor Activo" : "Servidor Detenido")
                            .font(.headline)
                    }
                    
                    Text(server.isRunning ? "Escuchando en \(server.serverURLString)" : "Inicia el servidor para recibir peticiones locales.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    if server.isRunning {
                        server.stopServer()
                    } else {
                        server.startServer()
                    }
                } label: {
                    Text(server.isRunning ? "Detener" : "Iniciar Servidor")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(server.isRunning ? Color.red.opacity(0.15) : Color.accentColor)
                        .foregroundColor(server.isRunning ? .red : .white)
                        .cornerRadius(10)
                }
            }
            
            if server.isRunning {
                Divider()
                
                HStack {
                    Label("\(server.totalRequestsServed) Peticiones servidas", systemImage: "arrow.up.arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = server.serverURLString
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Copiar URL")
                        }
                        .font(.caption2)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
    
    private var devInstructionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.accentColor)
                Text("Conectar Cursor / VS Code / Ollama Client")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Text("Puedes configurar tus herramientas de desarrollo apuntando a la dirección IP local de tu dispositivo:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("• OpenAI API Base URL:")
                    .font(.caption2)
                    .fontWeight(.bold)
                Text("\(server.serverURLString)/v1")
                    .font(.system(.caption, design: .monospaced))
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(6)
                
                Text("• Ollama Host URL:")
                    .font(.caption2)
                    .fontWeight(.bold)
                Text(server.serverURLString)
                    .font(.system(.caption, design: .monospaced))
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
    
    private var consoleLogsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Terminal Logs (Live)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(server.recentLogs.count) entradas")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if server.recentLogs.isEmpty {
                        Text("No hay logs registrados aún.")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                    } else {
                        ForEach(server.recentLogs.indices, id: \.self) { idx in
                            Text(server.recentLogs[idx])
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 160)
            .padding(10)
            .background(Color.black)
            .cornerRadius(10)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}
