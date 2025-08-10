# Dockerfile
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install basic deps and fonts for headless Chromium
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libgbm1 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxkbcommon0 \
    libpango-1.0-0 \
    libxshmfence1 \
    libxcursor1 \
    libxrender1 \
    libxcb1 \
    libxcb-dri3-0 \
    libexpat1 \
    fonts-liberation \
    fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# Set working dir
WORKDIR /app

# Copy requirements and app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Install Playwright browsers and dependencies
# playwright install --with-deps will try to install OS packages if possible, but we already installed common ones above.
RUN playwright install --with-deps chromium

# Copy app code
COPY app.py /app/app.py

# Expose port used by uvicorn
EXPOSE 8000

# Command
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
