FROM python:3.9-slim

WORKDIR /app

# Install dependencies securely
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

ENV DB_PATH=/data/application.db

EXPOSE 5000

# Use Gunicorn as the production application server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]