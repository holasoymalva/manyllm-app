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

## 3. Direct Communications
When you query a language model, the app communicates directly with:
* Your local Ollama instance (on your local network/localhost)
* The respective third-party API providers (OpenAI, Anthropic, Hugging Face) using your provided credentials.

These communications are subject to the privacy policies of those individual providers.

## 4. Contact
If you have any questions, you can contact the developer or open an issue on our official repository:
https://github.com/holasoymalva/manyllm-app
