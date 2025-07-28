# Voice Service - Reflect Feature

This is the voice AI assistant service for the Freewrite app's "reflect" feature. It uses the Livekit Agents framework to provide real-time voice conversations with an AI assistant named Kelly.

## Setup

1. **Install Python dependencies:**
   ```bash
   cd voice_service
   pip install -r requirements.txt
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```
   
   Then edit `.env` with your actual API keys:
   - **Livekit**: Get credentials from [Livekit Cloud](https://cloud.livekit.io/)
   - **OpenAI**: Get API key from [OpenAI](https://platform.openai.com/api-keys)
   - **Deepgram**: Get API key from [Deepgram](https://console.deepgram.com/)

## Running the Agent

```bash
cd voice_service
python agent.py start
```

## Features

- **Voice-to-Voice Conversation**: Real-time speech recognition and synthesis
- **AI Assistant**: Powered by GPT-4o-mini with a friendly personality
- **Multi-language Support**: Uses Deepgram's nova-3 model with multilingual support
- **Turn Detection**: Automatic conversation flow management

## Agent Configuration

The agent (Kelly) is configured to:
- Be concise and conversational for voice interactions
- Maintain a curious, friendly personality with humor
- Respond naturally to voice conversations

## Architecture

- **STT**: Deepgram Nova-3 (multilingual)
- **LLM**: OpenAI GPT-4o-mini
- **TTS**: OpenAI TTS (voice: ash)
- **VAD**: Silero Voice Activity Detection
- **Turn Detection**: Multilingual model

## Integration with Freewrite App

The voice service runs independently and can be integrated with the main Freewrite macOS app through WebRTC connections to the Livekit room. 