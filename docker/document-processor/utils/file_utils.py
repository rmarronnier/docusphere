import os
import magic
import re
from pathlib import Path
from typing import Optional

def get_file_type(file_path: str) -> str:
    """
    Détermine le type de fichier basé sur son contenu et son extension
    """
    try:
        # Détection par contenu avec python-magic
        mime_type = magic.from_file(file_path, mime=True)
        
        # Mapping des types MIME vers nos types internes
        mime_to_type = {
            'application/pdf': 'pdf',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx',
            'application/msword': 'doc',
            'text/plain': 'txt',
            'application/rtf': 'rtf',
            'text/rtf': 'rtf',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'pptx',
            'application/vnd.ms-powerpoint': 'ppt',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'xlsx',
            'application/vnd.ms-excel': 'xls',
            'text/csv': 'csv',
            'image/png': 'png',
            'image/jpeg': 'jpg',
            'image/tiff': 'tiff',
            'image/bmp': 'bmp',
            'image/gif': 'gif'
        }
        
        file_type = mime_to_type.get(mime_type)
        if file_type:
            return file_type
            
    except Exception:
        pass
    
    # Fallback sur l'extension si détection MIME échoue
    extension = Path(file_path).suffix.lower().lstrip('.')
    
    # Extensions supportées
    supported_extensions = {
        'pdf', 'docx', 'doc', 'txt', 'rtf',
        'pptx', 'ppt', 'xlsx', 'xls', 'csv',
        'png', 'jpg', 'jpeg', 'tiff', 'tif', 'bmp', 'gif'
    }
    
    if extension in supported_extensions:
        # Normalisation de certaines extensions
        if extension == 'jpeg':
            return 'jpg'
        elif extension == 'tif':
            return 'tiff'
        return extension
    
    raise ValueError(f"Type de fichier non supporté: {extension}")

def sanitize_filename(filename: str) -> str:
    """
    Nettoie un nom de fichier pour le rendre sûr
    """
    if not filename:
        return "unknown_file"
    
    # Suppression des caractères dangereux
    safe_filename = re.sub(r'[^\w\-_\.]', '_', filename)
    
    # Limitation de la longueur
    if len(safe_filename) > 255:
        name, ext = os.path.splitext(safe_filename)
        safe_filename = name[:250] + ext
    
    return safe_filename

def get_file_size_mb(file_path: str) -> float:
    """
    Retourne la taille du fichier en MB
    """
    size_bytes = os.path.getsize(file_path)
    return size_bytes / (1024 * 1024)

def is_file_too_large(file_path: str, max_size_mb: int = 100) -> bool:
    """
    Vérifie si un fichier est trop volumineux
    """
    return get_file_size_mb(file_path) > max_size_mb

def validate_file_path(file_path: str) -> bool:
    """
    Valide qu'un chemin de fichier est sûr et accessible
    """
    try:
        # Vérification de l'existence
        if not os.path.exists(file_path):
            return False
        
        # Vérification que c'est bien un fichier
        if not os.path.isfile(file_path):
            return False
        
        # Vérification des permissions de lecture
        if not os.access(file_path, os.R_OK):
            return False
        
        # Vérification contre les chemins dangereux
        real_path = os.path.realpath(file_path)
        if '..' in real_path or real_path.startswith('/'):
            # Autoriser seulement les chemins dans le répertoire de travail
            work_dir = os.path.realpath('/app')
            if not real_path.startswith(work_dir):
                return False
        
        return True
        
    except Exception:
        return False