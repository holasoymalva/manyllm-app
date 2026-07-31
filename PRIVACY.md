# Privacy Policy for ManyLLM

Last updated: July 27, 2026

At ManyLLM, we value your privacy. This Privacy Policy describes how we handle information in our iOS and iPadOS application.

## 1. No Data Collection
ManyLLM does not collect, store, or transmit any personal data or usage metrics to our own servers. We do not have any backend servers or databases.

## 2. Local Storage
All information generated or configured in the app, including:
* Your API Keys (OpenAI, Anthropic, Hugging Face)
* Your local Ollama Host URLs
* Your chat history and workspaces
* Your uploaded context files

is stored locally on your physical device. API keys are stored securely using standard iOS Keychain and UserDefaults.

## 3. Direct Communications & Data Sharing with Third-Party AI Services
When you write messages or query a language model within the app, the app collects and transmits your prompt text and any chosen context files (such as local text/PDF attachments) directly to:
* Your local Ollama instance (on your local network/localhost)
* The respective third-party API providers (OpenAI, Anthropic, or Hugging Face) using your provided API keys.

### 3.1 What Data is Shared
* **Chat Prompts:** The text messages you type in the chat input.
* **Context Files:** The contents of files you manually select and include in your active workspace context.

### 3.2 Purpose and Use of Data
The data is collected solely from your direct input inside the app and is sent to the selected AI provider for the single purpose of generating text responses. No data is shared in the background or for any marketing or tracking purposes.

### 3.3 Third-Party Privacy Policies
These communications are subject to the privacy policies of the individual third-party providers you configure:
* OpenAI Privacy Policy: https://openai.com/privacy/
* Anthropic Privacy Policy: https://www.anthropic.com/privacy
* Hugging Face Privacy Policy: https://huggingface.co/privacy

We confirm that we do not sell or share any user data with any other entity.

## 4. Contact
If you have any questions, you can contact the developer or open an issue on our official repository:
https://github.com/holasoymalva/manyllm-app
