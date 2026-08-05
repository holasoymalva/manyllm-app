//
//  LocalizationManager.swift
//  many-llms
//
//  Created by Antigravity on 8/5/26.
//

import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case spanish = "es"
    case english = "en"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .system: return "Sistema (System)"
        case .spanish: return "Español 🇪🇸"
        case .english: return "English 🇺🇸"
        }
    }
}

public final class LocalizationManager {
    public static let shared = LocalizationManager()
    
    private init() {}
    
    public func resolveLanguage(_ selected: AppLanguage) -> String {
        if selected == .system {
            let preferred = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "es"
            return (preferred == "es") ? "es" : "en"
        }
        return selected.rawValue
    }
    
    public func localizedString(forKey key: String, language: AppLanguage) -> String {
        let langCode = resolveLanguage(language)
        if langCode == "en", let translated = englishDictionary[key] {
            return translated
        }
        return spanishDictionary[key] ?? key
    }
    
    // MARK: - Translation Dictionaries
    private let spanishDictionary: [String: String] = [
        // App General
        "app_title": "ManyLLM",
        "welcome_title": "Bienvenido a ManyLLM",
        "welcome_subtitle": "Selecciona un modelo e ingresa tu consulta para comenzar.",
        "input_placeholder": "Escribe tu consulta...",
        "thinking": "Pensando...",
        "send": "Enviar",
        "copy": "Copiar",
        "cancel": "Cancelar",
        "ok": "OK",
        
        // Status Badges
        "status_ollama_active": "Ollama Activo",
        "status_local_network": "Red Local",
        "status_unchecked": "No comprobado",
        "status_connected": "Conectado",
        "status_offline": "Sin conexión",
        
        // Sidebar & Workspaces
        "section_workspaces": "Workspaces",
        "section_context_files": "Archivos de Contexto",
        "btn_new_chat": "+ Nuevo chat",
        "badge_active": "Active",
        "badge_coming_soon": "Próximamente",
        "chats": "Chats",
        "workspaces_and_projects": "Workspaces & Proyectos",
        "artifacts": "Artefactos",
        "code_and_sandbox": "Código & Sandbox",
        "files_in_context": "%d de %d archivos en contexto",
        
        // Settings
        "settings_title": "Configuración",
        "settings_language": "Idioma de la App",
        "settings_theme": "Aspecto / Tema",
        "theme_light": "Claro",
        "theme_dark": "Oscuro",
        "theme_system": "Sistema",
        "ollama_host_title": "URL Servidor Ollama",
        "ollama_test_connection": "Probar Conexión",
        "api_keys_title": "Claves de API (API Keys)",
        "openai_key": "OpenAI API Key",
        "anthropic_key": "Anthropic API Key",
        "huggingface_token": "Hugging Face Token",
        "custom_endpoint": "Endpoint Personalizado (OpenAI compatible)",
        "parameters_title": "Parámetros del Modelo",
        "temperature": "Temperatura",
        "max_tokens": "Tokens Máximos",
        "system_prompt": "Prompt de Sistema",
        
        // Privacy Consent
        "privacy_title": "Uso de Datos y Privacidad",
        "privacy_subtitle": "Para poder procesar tus consultas con inteligencia artificial, ManyLLM se conecta con servicios externos de procesamiento de lenguaje natural.",
        "privacy_what_data_title": "¿Qué información se transmite?",
        "privacy_what_data_body": "Únicamente los mensajes de chat que escribes y los archivos de contexto que selecciones explícitamente se envían al modelo de IA seleccionado para generar sus respuestas.",
        "privacy_who_data_title": "¿A quién se envían tus datos?",
        "privacy_who_data_body": "Los datos se envían de forma directa al proveedor del modelo configurado (como OpenAI, Anthropic, Hugging Face o tu servidor local de Ollama). ManyLLM no cuenta con servidores intermediarios, no recopila, no almacena ni rastrea tu información en bases de datos externas.",
        "privacy_security_title": "Seguridad Local",
        "privacy_security_body": "Tus claves de API (API Keys) y configuraciones personales se almacenan de manera local y encriptada en tu dispositivo (usando Keychain e iOS UserDefaults).",
        "privacy_link": "Leer la Política de Privacidad Completa",
        "privacy_accept": "Entiendo y Acepto",
        
        // Alerts & File Import
        "file_imported_title": "Archivo importado",
        "file_imported_msg": "El archivo '%@' se ha añadido exitosamente al contexto de ManyLLM."
    ]
    
    private let englishDictionary: [String: String] = [
        // App General
        "app_title": "ManyLLM",
        "welcome_title": "Welcome to ManyLLM",
        "welcome_subtitle": "Select a model and enter your query to begin.",
        "input_placeholder": "Type your query...",
        "thinking": "Thinking...",
        "send": "Send",
        "copy": "Copy",
        "cancel": "Cancel",
        "ok": "OK",
        
        // Status Badges
        "status_ollama_active": "Ollama Active",
        "status_local_network": "Local Network",
        "status_unchecked": "Unchecked",
        "status_connected": "Connected",
        "status_offline": "Offline",
        
        // Sidebar & Workspaces
        "section_workspaces": "Workspaces",
        "section_context_files": "Context Files",
        "btn_new_chat": "+ New chat",
        "badge_active": "Active",
        "badge_coming_soon": "Coming Soon",
        "chats": "Chats",
        "workspaces_and_projects": "Workspaces & Projects",
        "artifacts": "Artifacts",
        "code_and_sandbox": "Code & Sandbox",
        "files_in_context": "%d of %d files in context",
        
        // Settings
        "settings_title": "Settings",
        "settings_language": "App Language",
        "settings_theme": "Appearance / Theme",
        "theme_light": "Light",
        "theme_dark": "Dark",
        "theme_system": "System",
        "ollama_host_title": "Ollama Server URL",
        "ollama_test_connection": "Test Connection",
        "api_keys_title": "API Keys",
        "openai_key": "OpenAI API Key",
        "anthropic_key": "Anthropic API Key",
        "huggingface_token": "Hugging Face Token",
        "custom_endpoint": "Custom Endpoint (OpenAI compatible)",
        "parameters_title": "Model Parameters",
        "temperature": "Temperature",
        "max_tokens": "Max Tokens",
        "system_prompt": "System Prompt",
        
        // Privacy Consent
        "privacy_title": "Data Usage & Privacy",
        "privacy_subtitle": "To process your AI queries, ManyLLM connects with external natural language processing services.",
        "privacy_what_data_title": "What information is transmitted?",
        "privacy_what_data_body": "Only the text messages you write and the context files you explicitly select are transmitted to the chosen AI model to generate responses.",
        "privacy_who_data_title": "Who receives your data?",
        "privacy_who_data_body": "Data is sent directly to the provider of the configured model (such as OpenAI, Anthropic, Hugging Face, or your local Ollama server). ManyLLM has no intermediary servers and does not collect, store, or track your data on external databases.",
        "privacy_security_title": "Local Security",
        "privacy_security_body": "Your API Keys and personal settings are securely stored locally on your device (using iOS Keychain and UserDefaults).",
        "privacy_link": "Read Full Privacy Policy",
        "privacy_accept": "I Understand & Accept",
        
        // Alerts & File Import
        "file_imported_title": "File Imported",
        "file_imported_msg": "File '%@' has been successfully added to ManyLLM's context."
    ]
}
