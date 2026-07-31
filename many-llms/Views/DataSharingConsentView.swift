//
//  DataSharingConsentView.swift
//  many-llms
//
//  Created by Antigravity on 7/31/26.
//

import SwiftUI

public struct DataSharingConsentView: View {
    @ObservedObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    
    public init(store: WorkspaceStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
                .padding(.top, 40)
            
            // Title
            Text("Uso de Datos y Privacidad")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Explanatory ScrollView
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Para poder procesar tus consultas con inteligencia artificial, ManyLLM se conecta con servicios externos de procesamiento de lenguaje natural.")
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Qué información se transmite?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Únicamente los mensajes de chat que escribes y los archivos de contexto que selecciones explícitamente se envían al modelo de IA seleccionado para generar sus respuestas.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿A quién se envían tus datos?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Los datos se envían de forma directa al proveedor del modelo configurado (como OpenAI, Anthropic, Hugging Face o tu servidor local de Ollama). ManyLLM no cuenta con servidores intermediarios, no recopila, no almacena ni rastrea tu información en bases de datos externas.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seguridad Local")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Tus claves de API (API Keys) y configuraciones personales se almacenan de manera local y encriptada en tu dispositivo (usando Keychain e iOS UserDefaults).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    
                    if let privacyURL = URL(string: "https://github.com/holasoymalva/manyllm-app/blob/main/PRIVACY.md") {
                        Link(destination: privacyURL) {
                            HStack {
                                Text("Leer la Política de Privacidad Completa")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.orange)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Acceptance Button
            Button(action: {
                store.hasConsentedToDataSharing = true
                dismiss()
            }) {
                Text("Entiendo y Acepto")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.orange)
                    .cornerRadius(14)
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .interactiveDismissDisabled() // User must press the button to consent
    }
}
