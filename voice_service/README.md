# Voice Service - Reflect Feature

This is the voice AI assistant service for the Spillitout app's "reflect" feature. It combines a LiveKit voice agent with a token generation server, providing both real-time voice conversations and authentication for the Spillitout app.

## Features

- **Token Generation Server**: REST API endpoints for generating LiveKit access tokens
- **Voice AI Agent**: Real-time voice conversation with "Spill", an AI reflection assistant
- **Production Ready**: Deployable to render.com and other cloud platforms

## Setup

1. **Install Python dependencies:**
   ```bash
   cd voice_service
   pip install -r requirements.txt
   ```

2. **Configure environment variables:**
   ```bash
   cp env.example .env
   ```
   
   Then edit `.env` with your actual API keys:
   - **LIVEKIT_API_KEY**: API key from [LiveKit Cloud](https://cloud.livekit.io/)
   - **LIVEKIT_API_SECRET**: API secret from [LiveKit Cloud](https://cloud.livekit.io/)
   - **LIVEKIT_URL**: Your LiveKit server URL (e.g., wss://your-project-XXXXXXXX.livekit.cloud)
   - **OPENAI_API_KEY**: API key from [OpenAI](https://platform.openai.com/api-keys)
   - **DEEPGRAM_API_KEY**: API key from [Deepgram](https://console.deepgram.com/)
   - **PORT**: Server port (default: 8080)

## Development

### Running the Token Server

```bash
cd voice_service
python server.py
```

The server will start on `http://localhost:8080` and provide:
- Token generation at `/getToken` (GET and POST)
- Health check at `/`

### Running the Voice Agent

```bash
cd voice_service
python agent.py start
```


### Deploy Voice Agent to LiveKit Cloud

The voice agent (`agent.py`) should be deployed separately using LiveKit Cloud or your own infrastructure. Follow the [LiveKit Agents deployment guide](https://docs.livekit.io/agents/deployment/).


## Architecture

- **STT**: Deepgram Nova-3 (multilingual)
- **LLM**: OpenAI GPT-4o-mini
- **TTS**: OpenAI TTS (voice: ash)
- **VAD**: Silero Voice Activity Detection
- **Turn Detection**: Multilingual model

## Integration with Spillitout App

The voice service runs independently and can be integrated with the main macOS app through WebRTC connections to the Livekit room. 