# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11.6
FROM python:${PYTHON_VERSION}-slim

ENV PYTHONUNBUFFERED=1

ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/home/appuser" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    appuser

# Install build dependencies
RUN apt-get update && \
    apt-get install -y \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

USER appuser

RUN mkdir -p /home/appuser/.cache
RUN chown -R appuser /home/appuser/.cache

WORKDIR /home/appuser

COPY requirements.txt .
RUN python -m pip install --user --no-cache-dir -r requirements.txt

COPY . .

# Pre-download models that your agent uses
# Based on your agent.py, you use Silero VAD and potentially other models
RUN python agent.py download-files

# Create a startup script to run both services
RUN echo '#!/bin/bash\n\
python server.py &\n\
python agent.py start\n\
' > /home/appuser/start.sh && chmod +x /home/appuser/start.sh

# Run both services
CMD ["/home/appuser/start.sh"]