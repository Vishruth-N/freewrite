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

## Production Deployment

### Deploy Token Server to Render.com

1. **Create a new Web Service** on [Render.com](https://render.com)
2. **Connect your repository** containing the voice_service folder
3. **Configure the service:**
   - **Root Directory**: `voice_service`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python server.py`
   - **Port**: `8080`

4. **Set Environment Variables** in Render dashboard:
   ```
   LIVEKIT_API_KEY=your_livekit_api_key
   LIVEKIT_API_SECRET=your_livekit_api_secret
   LIVEKIT_URL=wss://your-project-XXXXXXXX.livekit.cloud
   PORT=8080
   ```

5. **Deploy** and get your token server URL (e.g., `https://your-app.onrender.com`)

### Update Your Swift App

Once deployed, update your `TokenService.swift` to use your production server:

```swift
private let productionServerUrl: String = "https://your-app.onrender.com"

private func fetchConnectionDetailsFromProduction(roomName: String, participantName: String) async throws -> ConnectionDetails? {
    var urlComponents = URLComponents(string: "\(productionServerUrl)/getToken")!
    urlComponents.queryItems = [
        URLQueryItem(name: "roomName", value: roomName),
        URLQueryItem(name: "participantName", value: participantName),
    ]
    
    let request = URLRequest(url: urlComponents.url!)
    let (data, response) = try await URLSession.shared.data(for: request)
    
    // Handle response...
}
```

### Deploy Voice Agent to LiveKit Cloud

The voice agent (`agent.py`) should be deployed separately using LiveKit Cloud or your own infrastructure. Follow the [LiveKit Agents deployment guide](https://docs.livekit.io/agents/deployment/).

## API Endpoints

### GET /getToken
Generate a token using query parameters:
```
GET /getToken?roomName=my-room&participantName=John&participantIdentity=user123
```

### POST /getToken
Generate a token using JSON body:
```json
{
  "roomName": "my-room",
  "participantName": "John", 
  "participantIdentity": "user123"
}
```

Both return:
```json
{
  "serverUrl": "wss://your-project-XXXXXXXX.livekit.cloud",
  "roomName": "my-room",
  "participantName": "John",
  "participantToken": "eyJhbGc..."
}
```
- **Multi-language Support**: Uses Deepgram's nova-3 model with multilingual support
- **Turn Detection**: Automatic conversation flow management

## Architecture

- **STT**: Deepgram Nova-3 (multilingual)
- **LLM**: OpenAI GPT-4o-mini
- **TTS**: OpenAI TTS (voice: ash)
- **VAD**: Silero Voice Activity Detection
- **Turn Detection**: Multilingual model

## Integration with Spillitout App

The voice service runs independently and can be integrated with the main Spillitout macOS app through WebRTC connections to the Livekit room. 