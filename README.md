# ManyLLM - iOS & iPadOS App 🐱🐝

**ManyLLM** es una aplicación nativa para iPhone e iPad desarrollada en SwiftUI que permite ejecutar y conectar modelos de lenguaje (LLMs) tanto de manera local (vía Ollama) como remota (OpenAI, Anthropic, HuggingFace), inspirada en la interfaz y experiencia de usuario de la app oficial de Claude para iOS.

---

## 🌟 Características Principales

- **Interfaz Estilo Claude para iOS / iPadOS**:
  - Pantalla principal de chat central con saludo y animación oficial del gatito-abeja.
  - Card flotante de entrada de prompt con menú de archivos de contexto, selector de modelo en píldora (`Llama 3 8B`, `Sonnet 3.5`, `DeepSeek R1`) y botón de envío.
  - Drawer lateral deslizable con acceso a **Workspaces**, **Archivos de Contexto**, **Chats** y botón flotante `+ Nuevo chat`.

- **Conexión Local & Remota de Modelos**:
  - **Ollama Host Local**: Conexión REST streaming a instancias de Ollama en `http://localhost:11434` o en la red local.
  - **APIs de la Nube**: Configuración de claves de API para OpenAI (GPT-4o), Anthropic (Claude 3.5 Sonnet) y Hugging Face Inference API.

- **Formateo de Markdown y Bloques de Código**:
  - Renderizado automático de respuestas con soporte para bloques de código ` ```swift ... ``` ` presentados en tarjetas oscuras con resaltado y botón de copiado rápido.

- **Espacios de Trabajo y Contexto de Archivos**:
  - Organiza conversaciones en diferentes **Workspaces** (*Current Chat*, *Research Project*, *Code Review*).
  - Incluye o excluye archivos de contexto (`.md`, `.pdf`, `.txt`) con selectores visuales de ojo.

- **Modal de Configuración y Personalización**:
  - Tarjetas redondeadas para ajustar hosts, API keys y selector visual de aspecto (**Claro**, **Oscuro**, **Sistema**).

---

## 📱 Requisitos

- **iOS / iPadOS**: 16.0 o superior.
- **Xcode**: 15.0 o superior.
- **Swift**: 5.9+

---

## 🚀 Instalación y Uso

1. **Clonar el repositorio**:
   ```bash
   git clone https://github.com/holasoymalva/manyllm-app.git
   cd manyllm-app
   ```

2. **Abrir en Xcode**:
   ```bash
   open many-llms.xcodeproj
   ```

3. **Compilar y Ejecutar**:
   - Selecciona un simulador o dispositivo (iPhone / iPad) y presiona `Cmd + R`.

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.
