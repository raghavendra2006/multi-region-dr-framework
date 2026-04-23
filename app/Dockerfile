FROM python:3.9-slim

WORKDIR /app

# Install system dependencies for health checks and database operations
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl sqlite3 && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies securely
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Create a non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

ENV DB_PATH=/data/application.db

EXPOSE 5000

# Use Gunicorn as the production application server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--access-logfile", "-", "app:app"]