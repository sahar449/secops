# Stage 1: Build and install dependencies
FROM python:3.11-slim AS builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends build-essential gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python dependencies into a separate install directory
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# Copy source code
COPY main.py .

# Stage 2: Minimal runtime
FROM python:3.11-slim

# Create user with specific UID that matches Kubernetes
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid 1000 --create-home appuser

WORKDIR /app

# Copy installed Python packages and app file from builder
COPY --from=builder /install /usr/local
COPY --from=builder /app/main.py .

# Set file ownership and permissions for UID 1000
RUN chown -R 1000:1000 /app && \
    chmod 644 main.py

# Use non-root user
USER 1000

EXPOSE 5000

CMD ["python", "main.py"]