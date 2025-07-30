import os
import logging
from datetime import timedelta
from typing import Optional

import uvicorn
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# LiveKit imports
from livekit import api

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("spillitout-token-server")

# FastAPI app
app = FastAPI(title="Spillitout Token Server", description="LiveKit token generation service")

# CORS middleware for frontend connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Environment variables
LIVEKIT_API_KEY = os.getenv("LIVEKIT_API_KEY")
LIVEKIT_API_SECRET = os.getenv("LIVEKIT_API_SECRET")
LIVEKIT_URL = os.getenv("LIVEKIT_URL")

if not LIVEKIT_API_KEY or not LIVEKIT_API_SECRET:
    logger.warning("LIVEKIT_API_KEY and LIVEKIT_API_SECRET must be set")

# Pydantic models
class TokenRequest(BaseModel):
    roomName: str
    participantName: str
    participantIdentity: Optional[str] = None

class TokenResponse(BaseModel):
    serverUrl: str
    roomName: str
    participantName: str
    participantToken: str

# Token generation function
def generate_token(room_name: str, participant_name: str, participant_identity: Optional[str] = None) -> str:
    """
    Generate a LiveKit access token for the given room and participant.
    Based on: https://docs.livekit.io/home/server/generating-tokens/
    """
    if not LIVEKIT_API_KEY or not LIVEKIT_API_SECRET:
        raise HTTPException(status_code=500, detail="Server configuration error: Missing API credentials")
    
    # Use participant_identity if provided, otherwise use participant_name
    identity = participant_identity or participant_name
    
    # Create access token following the LiveKit documentation pattern
    token = api.AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET) \
        .with_identity(identity) \
        .with_name(participant_name) \
        .with_grants(api.VideoGrants(
            room_join=True,
            room=room_name,
        )) \
        .with_ttl(timedelta(hours=1))
    
    return token.to_jwt()

# API Routes
@app.get("/")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "spillitout-token-server"}

@app.get("/getToken")
async def get_token_get(
    roomName: str = Query(..., description="Name of the room to join"),
    participantName: str = Query(..., description="Display name of the participant"),
    participantIdentity: Optional[str] = Query(None, description="Unique identity of the participant")
):
    """
    Generate a LiveKit access token (GET method for simple frontend integration)
    """
    try:
        token = generate_token(roomName, participantName, participantIdentity)
        return TokenResponse(
            serverUrl=LIVEKIT_URL,
            roomName=roomName,
            participantName=participantName,
            participantToken=token
        )
    except Exception as e:
        logger.error(f"Error generating token: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/getToken")
async def get_token_post(request: TokenRequest):
    """
    Generate a LiveKit access token (POST method for more complex requests)
    """
    try:
        token = generate_token(request.roomName, request.participantName, request.participantIdentity)
        return TokenResponse(
            serverUrl=LIVEKIT_URL,
            roomName=request.roomName,
            participantName=request.participantName,
            participantToken=token
        )
    except Exception as e:
        logger.error(f"Error generating token: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    # For development
    port = int(os.getenv("PORT", 8080))
    uvicorn.run(
        "server:app",
        host="0.0.0.0",
        port=port,
        reload=True,
        log_level="info"
    )