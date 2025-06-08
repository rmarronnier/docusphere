FROM python:3.11-slim

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    # LibreOffice pour la conversion de documents
    libreoffice \
    # Tesseract pour l'OCR
    tesseract-ocr \
    tesseract-ocr-fra \
    tesseract-ocr-eng \
    # Outils de traitement d'images
    imagemagick \
    # Outils pour PDF
    poppler-utils \
    ghostscript \
    # Outils pour traitement vidéo/audio (optionnel)
    ffmpeg \
    # Outils système
    curl \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Configuration d'ImageMagick pour autoriser PDF
RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml && \
    sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/g' /etc/ImageMagick-6/policy.xml

# Création du répertoire de travail
WORKDIR /app

# Installation des dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Installation de modèles IA légers
RUN python -c "import nltk; nltk.download('punkt'); nltk.download('stopwords'); nltk.download('wordnet')"

# Copie du code de l'application
COPY . .

# Création des répertoires de travail
RUN mkdir -p /app/temp /app/output /app/models

# Variables d'environnement
ENV PYTHONPATH=/app
ENV TEMP_DIR=/app/temp
ENV OUTPUT_DIR=/app/output
ENV MODELS_DIR=/app/models

# Port d'exposition
EXPOSE 8000

# Commande de démarrage
CMD ["python", "main.py"]