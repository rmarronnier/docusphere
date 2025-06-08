import redis
import json
import pickle
from typing import Any, Optional
from loguru import logger
import os

class CacheManager:
    """
    Gestionnaire de cache Redis pour les résultats de traitement
    """
    
    def __init__(self):
        self.redis_host = os.environ.get('REDIS_HOST', 'redis')
        self.redis_port = int(os.environ.get('REDIS_PORT', 6379))
        self.redis_db = int(os.environ.get('REDIS_DB', 0))
        
        try:
            self.redis_client = redis.Redis(
                host=self.redis_host,
                port=self.redis_port,
                db=self.redis_db,
                decode_responses=False,  # Pour pouvoir stocker des bytes
                socket_timeout=5,
                socket_connect_timeout=5
            )
            
            # Test de connexion
            self.redis_client.ping()
            logger.info(f"Connexion Redis établie: {self.redis_host}:{self.redis_port}")
            
        except Exception as e:
            logger.warning(f"Impossible de se connecter à Redis: {e}")
            self.redis_client = None
    
    async def get(self, key: str) -> Optional[Any]:
        """
        Récupère une valeur du cache
        """
        if not self.redis_client:
            return None
        
        try:
            cached_data = self.redis_client.get(key)
            if cached_data:
                # Tentative de désérialisation JSON d'abord
                try:
                    return json.loads(cached_data.decode('utf-8'))
                except (json.JSONDecodeError, UnicodeDecodeError):
                    # Fallback vers pickle
                    return pickle.loads(cached_data)
            
            return None
            
        except Exception as e:
            logger.error(f"Erreur lecture cache pour {key}: {e}")
            return None
    
    async def set(self, key: str, value: Any, expire: int = 3600) -> bool:
        """
        Stocke une valeur dans le cache
        """
        if not self.redis_client:
            return False
        
        try:
            # Tentative de sérialisation JSON d'abord
            try:
                serialized_data = json.dumps(value, ensure_ascii=False)
            except (TypeError, ValueError):
                # Fallback vers pickle pour les objets complexes
                serialized_data = pickle.dumps(value)
            
            result = self.redis_client.setex(key, expire, serialized_data)
            return bool(result)
            
        except Exception as e:
            logger.error(f"Erreur écriture cache pour {key}: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """
        Supprime une clé du cache
        """
        if not self.redis_client:
            return False
        
        try:
            result = self.redis_client.delete(key)
            return bool(result)
            
        except Exception as e:
            logger.error(f"Erreur suppression cache pour {key}: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """
        Vérifie si une clé existe dans le cache
        """
        if not self.redis_client:
            return False
        
        try:
            return bool(self.redis_client.exists(key))
            
        except Exception as e:
            logger.error(f"Erreur vérification existence cache pour {key}: {e}")
            return False
    
    def get_stats(self) -> dict:
        """
        Retourne des statistiques sur le cache
        """
        if not self.redis_client:
            return {'status': 'disconnected'}
        
        try:
            info = self.redis_client.info()
            return {
                'status': 'connected',
                'used_memory': info.get('used_memory_human', 'unknown'),
                'connected_clients': info.get('connected_clients', 0),
                'total_commands_processed': info.get('total_commands_processed', 0),
                'keyspace_hits': info.get('keyspace_hits', 0),
                'keyspace_misses': info.get('keyspace_misses', 0)
            }
            
        except Exception as e:
            logger.error(f"Erreur récupération stats Redis: {e}")
            return {'status': 'error', 'error': str(e)}
    
    async def clear_cache(self, pattern: str = "*") -> int:
        """
        Vide le cache selon un pattern
        """
        if not self.redis_client:
            return 0
        
        try:
            keys = self.redis_client.keys(pattern)
            if keys:
                deleted = self.redis_client.delete(*keys)
                logger.info(f"Suppression de {deleted} clés du cache")
                return deleted
            return 0
            
        except Exception as e:
            logger.error(f"Erreur vidage cache: {e}")
            return 0