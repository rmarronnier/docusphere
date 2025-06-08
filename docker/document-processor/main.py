from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn
import os
import tempfile
import shutil
from typing import Optional, List, Dict, Any
from loguru import logger

from processors.document_processor import DocumentProcessor
from processors.ai_classifier import AIClassifier
from utils.file_utils import get_file_type, sanitize_filename
from utils.cache import CacheManager

# Configuration de l'application
app = FastAPI(
    title="Document Processing Service",
    description="Service d'extraction et de classification de contenu de documents",
    version="1.0.0"
)

# Initialisation des services
document_processor = DocumentProcessor()
ai_classifier = AIClassifier()
cache_manager = CacheManager()

# Modèles Pydantic
class ProcessingResult(BaseModel):
    file_id: str
    file_type: str
    text_content: str
    metadata: Dict[str, Any]
    classification: Optional[Dict[str, Any]] = None
    entities: Optional[List[Dict[str, Any]]] = None
    summary: Optional[str] = None
    processing_time: float
    status: str

class ProcessingRequest(BaseModel):
    extract_text: bool = True
    perform_ocr: bool = True
    classify_document: bool = True
    extract_entities: bool = True
    generate_summary: bool = False
    language: str = "fr"

@app.get("/health")
async def health_check():
    """Vérification de l'état du service"""
    return {"status": "healthy", "service": "document-processor"}

@app.post("/process", response_model=ProcessingResult)
async def process_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    extract_text: bool = True,
    perform_ocr: bool = True,
    classify_document: bool = True,
    extract_entities: bool = True,
    generate_summary: bool = False,
    language: str = "fr"
):
    """
    Traite un document uploadé et extrait le contenu selon les options spécifiées
    """
    import time
    start_time = time.time()
    
    # Génération d'un ID unique pour le fichier
    file_id = f"{int(time.time())}_{sanitize_filename(file.filename)}"
    
    try:
        # Vérification du cache
        cache_key = f"doc:{file_id}:{hash(file.filename + str(file.size))}"
        cached_result = await cache_manager.get(cache_key)
        if cached_result:
            logger.info(f"Résultat en cache pour {file_id}")
            return cached_result
        
        # Sauvegarde temporaire du fichier
        temp_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=f"_{file.filename}") as temp_file:
                temp_path = temp_file.name
                content = await file.read()
                temp_file.write(content)
            
            # Détection du type de fichier
            file_type = get_file_type(temp_path)
            logger.info(f"Traitement du fichier {file_id} de type {file_type}")
            
            # Traitement du document
            result = await document_processor.process_file(
                temp_path,
                file_type=file_type,
                extract_text=extract_text,
                perform_ocr=perform_ocr,
                language=language
            )
            
            # Classification IA si demandée
            classification = None
            entities = None
            summary = None
            
            if classify_document and result.get('text_content'):
                classification = await ai_classifier.classify_document(
                    result['text_content'],
                    language=language
                )
            
            if extract_entities and result.get('text_content'):
                entities = await ai_classifier.extract_entities(
                    result['text_content'],
                    language=language
                )
            
            if generate_summary and result.get('text_content'):
                summary = await ai_classifier.generate_summary(
                    result['text_content'],
                    language=language
                )
            
            processing_time = time.time() - start_time
            
            # Construction du résultat
            final_result = ProcessingResult(
                file_id=file_id,
                file_type=file_type,
                text_content=result.get('text_content', ''),
                metadata=result.get('metadata', {}),
                classification=classification,
                entities=entities,
                summary=summary,
                processing_time=processing_time,
                status="success"
            )
            
            # Mise en cache du résultat
            background_tasks.add_task(
                cache_manager.set,
                cache_key,
                final_result.dict(),
                expire=3600  # 1 heure
            )
            
            logger.info(f"Traitement réussi pour {file_id} en {processing_time:.2f}s")
            return final_result
            
        finally:
            # Nettoyage du fichier temporaire
            if temp_path and os.path.exists(temp_path):
                os.unlink(temp_path)
                
    except Exception as e:
        logger.error(f"Erreur lors du traitement de {file_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur de traitement: {str(e)}")

@app.post("/classify-text")
async def classify_text(
    text: str,
    language: str = "fr"
):
    """
    Classifie un texte sans traitement de fichier
    """
    try:
        classification = await ai_classifier.classify_document(text, language=language)
        entities = await ai_classifier.extract_entities(text, language=language)
        
        return {
            "classification": classification,
            "entities": entities,
            "status": "success"
        }
        
    except Exception as e:
        logger.error(f"Erreur lors de la classification: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur de classification: {str(e)}")

@app.get("/supported-formats")
async def get_supported_formats():
    """
    Retourne la liste des formats supportés
    """
    return {
        "text_extraction": [
            "pdf", "docx", "doc", "txt", "rtf",
            "pptx", "ppt", "xlsx", "xls", "csv"
        ],
        "ocr_supported": [
            "pdf", "png", "jpg", "jpeg", "tiff", "bmp", "gif"
        ],
        "classification_types": [
            "invoice", "contract", "report", "letter", "form",
            "technical_doc", "legal_doc", "financial_doc"
        ]
    }

@app.get("/metrics")
async def get_metrics():
    """
    Métriques du service pour monitoring
    """
    # Ici vous pourriez ajouter des métriques Prometheus
    return {
        "documents_processed": cache_manager.get_stats(),
        "service_uptime": "OK",
        "memory_usage": "OK"
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )