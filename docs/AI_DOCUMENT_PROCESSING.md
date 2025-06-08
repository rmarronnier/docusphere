# Système d'extraction et de classification IA de documents

## Vue d'ensemble

Ce système intègre un service d'intelligence artificielle pour l'extraction et la classification automatique du contenu des documents. Il combine des outils d'extraction classiques (LibreOffice, Tesseract) avec des modèles d'IA pour une analyse avancée.

## Architecture

### Composants principaux

1. **Service Docker d'extraction** (`document-processor`)
   - Service Python FastAPI autonome
   - Extraction de contenu via LibreOffice, Tesseract OCR
   - Classification IA avec modèles légers
   - Cache Redis pour performances

2. **Application Rails principale**
   - Service `DocumentProcessingService` pour communication API
   - Job `DocumentAiProcessingJob` pour traitement asynchrone
   - Modèle `Document` étendu avec champs IA
   - Composant `AiInsightsComponent` pour affichage

### Flux de traitement

```
1. Upload document → Document créé
2. Traitement de base (virus scan, metadata)
3. → DocumentAiProcessingJob (asynchrone)
4. → DocumentProcessingService
5. → Service d'extraction (Docker)
6. → Stockage résultats IA dans Document
7. → Affichage insights dans l'interface
```

## Service d'extraction Docker

### Fonctionnalités

- **Extraction de texte** : PDF, DOCX, TXT, images
- **OCR intelligent** : Tesseract avec préprocessing d'images
- **Classification** : Par mots-clés + modèles ML légers
- **Extraction d'entités** : Emails, téléphones, montants, dates, SIRET
- **Résumé automatique** : Pour documents longs
- **Cache Redis** : Évite retraitement

### Formats supportés

#### Extraction de texte
- PDF (avec fallback OCR)
- DOCX, DOC (via LibreOffice)
- PPTX, PPT
- XLSX, XLS
- TXT, RTF, CSV

#### OCR (reconnaissance optique)
- PNG, JPEG, TIFF, BMP, GIF
- PDF scannés

### Modèles IA intégrés

#### Classification de documents
- **Types détectés** : facture, contrat, rapport, lettre, formulaire, doc technique/juridique/financier
- **Approche hybride** : Mots-clés + ML (scikit-learn)
- **Confiance** : Score de 0 à 100%

#### Extraction d'entités
- **Regex patterns** : Structures connues (emails, phones, etc.)
- **NLP patterns** : Entités nommées françaises
- **Post-processing** : Déduplication et validation

#### Résumé automatique
- **Modèle Transformers** : BART pour résumés abstractifs
- **Fallback extractif** : Sélection de phrases clés
- **Limitation** : Documents > 50 mots

## Configuration et déploiement

### Variables d'environnement

```env
# Service d'extraction
DOCUMENT_PROCESSOR_URL=http://document-processor:8000
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=1
```

### Démarrage avec Docker Compose

```bash
# Démarrage de tous les services
docker-compose up -d

# Service d'extraction uniquement
docker-compose up document-processor

# Vérification santé
curl http://localhost:8000/health
```

### Volumes Docker

- `document_processor_temp` : Fichiers temporaires
- `document_processor_output` : Résultats de traitement
- `document_processor_models` : Modèles IA mis en cache

## API du service d'extraction

### Endpoints principaux

#### `POST /process`
Traitement complet d'un document

```json
{
  "file": "<fichier_multipart>",
  "extract_text": true,
  "perform_ocr": true,
  "classify_document": true,
  "extract_entities": true,
  "generate_summary": false,
  "language": "fr"
}
```

**Réponse** :
```json
{
  "file_id": "timestamp_filename",
  "file_type": "pdf",
  "text_content": "Contenu extrait...",
  "metadata": {"pages": 5, "author": "..."},
  "classification": {
    "keyword_classification": {"top_category": "invoice", "confidence": 0.85},
    "ml_classification": {"category": "invoice", "confidence": 0.92}
  },
  "entities": [
    {"type": "email", "value": "test@example.com", "confidence": 0.95}
  ],
  "summary": "Résumé du document...",
  "processing_time": 2.5,
  "status": "success"
}
```

#### `POST /classify-text`
Classification de texte uniquement

#### `GET /supported-formats`
Formats supportés par le service

#### `GET /health`
Vérification de l'état du service

## Intégration Rails

### Modèle Document étendu

Nouveaux champs :
```ruby
# Contenu extrait
extracted_text: text

# Classification IA
ai_category: string
ai_confidence: decimal
ai_classification_data: json

# Entités et résumé
ai_entities: json
ai_summary: text

# Métadonnées
ai_processed_at: datetime
```

### Méthodes utiles

```ruby
# Vérifications
document.ai_processed?
document.supports_ai_processing?

# Classification
document.ai_classification_category
document.ai_classification_confidence_percent

# Entités par type
document.ai_extracted_emails
document.ai_extracted_phones
document.ai_entities_by_type('amount')
```

### Service DocumentProcessingService

```ruby
# Traitement complet
service = DocumentProcessingService.new
service.process_document(document)

# Classification de texte uniquement
result = service.classify_text("Texte à analyser")

# Vérification de santé
service.health_check
```

### Job asynchrone

```ruby
# Lancement manuel
DocumentAiProcessingJob.perform_later(document_id)

# Automatique après traitement de base
# Via callback dans Document#should_process_with_ai?
```

## Interface utilisateur

### Composant AiInsightsComponent

Affichage des résultats IA :
- Badge de classification avec niveau de confiance
- Liste des entités extraites avec icônes
- Résumé automatique si disponible
- Aperçu du texte extrait
- Indicateurs de statut de traitement

### Utilisation dans les vues

```erb
<%= render Documents::AiInsightsComponent.new(document: @document) %>
```

## Performances et optimisations

### Cache Redis
- **Clé** : `doc:{file_id}:{hash}`
- **TTL** : 1 heure par défaut
- **Contenu** : Résultats complets de traitement

### Optimisations
- **Traitement asynchrone** : Jobs Sidekiq
- **Pré-processing d'images** : Amélioration OCR
- **Modèles légers** : Équilibre performance/précision
- **Fallbacks intelligents** : OCR si extraction directe échoue

## Monitoring et logs

### Health checks
```bash
# Service d'extraction
curl http://localhost:8000/health

# Métriques
curl http://localhost:8000/metrics
```

### Logs Rails
```ruby
Rails.logger.info "Traitement IA démarré pour document #{id}"
Rails.logger.error "Service d'extraction non disponible"
```

### Logs Python (service)
```python
logger.info(f"Traitement du fichier {file_id} de type {file_type}")
logger.error(f"Erreur OCR: {error}")
```

## Extensibilité

### Ajout de nouveaux types de documents
1. Étendre `document_categories` dans `ai_classifier.py`
2. Ajouter patterns d'extraction spécifiques
3. Mettre à jour l'interface utilisateur

### Ajout de nouveaux modèles IA
1. Intégrer dans `_load_transformer_models()`
2. Configurer dans `requirements.txt`
3. Adapter la logique de classification

### Ajout de langues
1. Configurer Tesseract (`lang_map`)
2. Ajouter stopwords NLTK
3. Adapter patterns d'entités

## Sécurité

### Isolation
- Service d'extraction dans container séparé
- Pas d'accès direct aux fichiers Rails
- Communication via API uniquement

### Validation
- Vérification des types de fichiers
- Limitation de taille (100MB)
- Sanitisation des noms de fichiers
- Nettoyage automatique des fichiers temporaires

### Données sensibles
- Pas de stockage permanent dans le service d'extraction
- Cache Redis avec expiration
- Logs sans informations personnelles

## Troubleshooting

### Problèmes courants

1. **Service d'extraction non disponible**
   - Vérifier `docker-compose ps`
   - Consulter `docker-compose logs document-processor`

2. **OCR de mauvaise qualité**
   - Vérifier la qualité de l'image source
   - Ajuster le préprocessing dans `_preprocess_image_for_ocr`

3. **Classification incorrecte**
   - Vérifier les mots-clés dans `document_categories`
   - Analyser `ai_classification_data` pour debugging

4. **Performances lentes**
   - Vérifier l'état du cache Redis
   - Monitorer l'utilisation CPU/mémoire
   - Considérer l'ajustement des modèles IA

### Commandes de diagnostic

```bash
# État des services
docker-compose ps

# Logs détaillés
docker-compose logs -f document-processor

# Vérification santé
curl -f http://localhost:8000/health || echo "Service DOWN"

# Formats supportés
curl http://localhost:8000/supported-formats

# Stats Redis
docker-compose exec redis redis-cli info memory
```

Ce système offre une solution complète et extensible pour l'analyse automatique de documents, combinant robustesse technique et facilité d'utilisation.