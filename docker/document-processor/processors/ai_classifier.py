import asyncio
from typing import Dict, List, Any, Optional
from loguru import logger
import re
import json
from collections import Counter

# IA/ML imports
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
import pickle
import os

# NLP imports
import nltk
from nltk.tokenize import word_tokenize, sent_tokenize
from nltk.corpus import stopwords
from nltk.stem import SnowballStemmer

# Transformers pour modèles plus avancés
try:
    from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification
    from sentence_transformers import SentenceTransformer
    TRANSFORMERS_AVAILABLE = True
except ImportError:
    TRANSFORMERS_AVAILABLE = False
    logger.warning("Transformers non disponibles, utilisation des modèles basiques uniquement")

class AIClassifier:
    """
    Service de classification et d'extraction IA pour documents
    """
    
    def __init__(self):
        self.models_dir = os.environ.get('MODELS_DIR', '/app/models')
        os.makedirs(self.models_dir, exist_ok=True)
        
        # Initialisation des ressources NLP
        self._setup_nltk()
        
        # Chargement des modèles
        self.document_classifier = None
        self.entity_extractor = None
        self.summarizer = None
        self.sentence_transformer = None
        
        # Initialisation asynchrone des modèles
        asyncio.create_task(self._load_models())
        
        # Patterns pour extraction d'entités
        self.entity_patterns = {
            'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            'phone': r'\b(?:\+33|0)[1-9](?:[0-9]{8})\b',
            'date': r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b',
            'amount': r'\b\d+[,.]?\d*\s*€?\s*euros?\b',
            'siret': r'\b\d{14}\b',
            'siren': r'\b\d{9}\b'
        }
        
        # Catégories de documents
        self.document_categories = {
            'invoice': {
                'keywords': ['facture', 'invoice', 'montant', 'tva', 'total', 'paiement'],
                'description': 'Facture commerciale'
            },
            'contract': {
                'keywords': ['contrat', 'contract', 'partie', 'conditions', 'engagement', 'signature'],
                'description': 'Contrat ou accord'
            },
            'report': {
                'keywords': ['rapport', 'report', 'analyse', 'résultat', 'conclusion', 'étude'],
                'description': 'Rapport ou étude'
            },
            'letter': {
                'keywords': ['lettre', 'letter', 'monsieur', 'madame', 'cordialement', 'salutations'],
                'description': 'Courrier ou lettre'
            },
            'form': {
                'keywords': ['formulaire', 'form', 'demande', 'candidature', 'inscription'],
                'description': 'Formulaire administratif'
            },
            'technical_doc': {
                'keywords': ['technique', 'technical', 'manuel', 'guide', 'procédure', 'installation'],
                'description': 'Documentation technique'
            },
            'legal_doc': {
                'keywords': ['légal', 'legal', 'juridique', 'loi', 'article', 'tribunal'],
                'description': 'Document juridique'
            },
            'financial_doc': {
                'keywords': ['financier', 'financial', 'budget', 'coût', 'investissement', 'comptable'],
                'description': 'Document financier'
            }
        }
    
    def _setup_nltk(self):
        """
        Configuration des ressources NLTK
        """
        try:
            # Vérification et téléchargement des ressources NLTK
            nltk.data.find('tokenizers/punkt')
            nltk.data.find('corpora/stopwords')
        except LookupError:
            logger.info("Téléchargement des ressources NLTK...")
            nltk.download('punkt', quiet=True)
            nltk.download('stopwords', quiet=True)
            nltk.download('wordnet', quiet=True)
    
    async def _load_models(self):
        """
        Chargement asynchrone des modèles IA
        """
        try:
            # Chargement du modèle de classification simple
            await self._load_simple_classifier()
            
            # Chargement des modèles transformers si disponibles
            if TRANSFORMERS_AVAILABLE:
                await self._load_transformer_models()
            
            logger.info("Modèles IA chargés avec succès")
            
        except Exception as e:
            logger.error(f"Erreur lors du chargement des modèles: {e}")
    
    async def _load_simple_classifier(self):
        """
        Chargement ou création d'un classificateur simple
        """
        classifier_path = os.path.join(self.models_dir, 'document_classifier.pkl')
        
        if os.path.exists(classifier_path):
            with open(classifier_path, 'rb') as f:
                self.document_classifier = pickle.load(f)
            logger.info("Classificateur chargé depuis le cache")
        else:
            # Création d'un classificateur basique avec données d'entraînement minimales
            self.document_classifier = Pipeline([
                ('tfidf', TfidfVectorizer(max_features=1000, stop_words='english')),
                ('classifier', MultinomialNB())
            ])
            
            # Entraînement avec données synthétiques
            await self._train_simple_classifier()
            
            # Sauvegarde
            with open(classifier_path, 'wb') as f:
                pickle.dump(self.document_classifier, f)
            
            logger.info("Nouveau classificateur créé et sauvegardé")
    
    async def _train_simple_classifier(self):
        """
        Entraînement basique du classificateur
        """
        # Données d'entraînement synthétiques
        training_data = []
        labels = []
        
        for category, info in self.document_categories.items():
            # Génération de textes synthétiques pour chaque catégorie
            for _ in range(10):
                text = ' '.join(info['keywords'] * 2)  # Simulation de texte
                training_data.append(text)
                labels.append(category)
        
        # Entraînement
        self.document_classifier.fit(training_data, labels)
    
    async def _load_transformer_models(self):
        """
        Chargement des modèles Transformers
        """
        try:
            # Modèle de résumé en français
            self.summarizer = pipeline(
                "summarization",
                model="facebook/bart-large-cnn",
                device=-1  # CPU
            )
            
            # Modèle d'embeddings pour similarité
            self.sentence_transformer = SentenceTransformer('all-MiniLM-L6-v2')
            
            logger.info("Modèles Transformers chargés")
            
        except Exception as e:
            logger.warning(f"Impossible de charger les modèles Transformers: {e}")
    
    async def classify_document(self, text: str, language: str = "fr") -> Dict[str, Any]:
        """
        Classification d'un document
        """
        try:
            # Nettoyage du texte
            cleaned_text = self._clean_text(text)
            
            # Classification par mots-clés (rapide)
            keyword_classification = self._classify_by_keywords(cleaned_text)
            
            # Classification ML si modèle disponible
            ml_classification = None
            if self.document_classifier:
                try:
                    prediction = self.document_classifier.predict([cleaned_text])[0]
                    probabilities = self.document_classifier.predict_proba([cleaned_text])[0]
                    confidence = max(probabilities)
                    
                    ml_classification = {
                        'category': prediction,
                        'confidence': float(confidence),
                        'all_probabilities': dict(zip(self.document_classifier.classes_, probabilities))
                    }
                except Exception as e:
                    logger.warning(f"Erreur classification ML: {e}")
            
            # Analyse de contenu
            content_analysis = self._analyze_content(cleaned_text)
            
            return {
                'keyword_classification': keyword_classification,
                'ml_classification': ml_classification,
                'content_analysis': content_analysis,
                'language_detected': language
            }
            
        except Exception as e:
            logger.error(f"Erreur classification: {e}")
            raise
    
    async def extract_entities(self, text: str, language: str = "fr") -> List[Dict[str, Any]]:
        """
        Extraction d'entités du texte
        """
        entities = []
        
        try:
            # Extraction par expressions régulières
            for entity_type, pattern in self.entity_patterns.items():
                matches = re.finditer(pattern, text, re.IGNORECASE)
                for match in matches:
                    entities.append({
                        'type': entity_type,
                        'value': match.group(),
                        'start': match.start(),
                        'end': match.end(),
                        'confidence': 0.8  # Confiance fixe pour regex
                    })
            
            # Extraction d'entités nommées avec NLTK
            named_entities = self._extract_named_entities(text)
            entities.extend(named_entities)
            
            # Dédoublonnage
            entities = self._deduplicate_entities(entities)
            
            return entities
            
        except Exception as e:
            logger.error(f"Erreur extraction entités: {e}")
            return []
    
    async def generate_summary(self, text: str, language: str = "fr", max_length: int = 150) -> Optional[str]:
        """
        Génération de résumé
        """
        try:
            # Nettoyage du texte
            cleaned_text = self._clean_text(text)
            
            # Si le texte est trop court, pas de résumé
            if len(cleaned_text.split()) < 50:
                return None
            
            # Résumé avec Transformers si disponible
            if self.summarizer and TRANSFORMERS_AVAILABLE:
                try:
                    # Limitation de la taille d'entrée
                    input_text = cleaned_text[:1024]  # Limitation Transformers
                    
                    summary = self.summarizer(
                        input_text,
                        max_length=max_length,
                        min_length=30,
                        do_sample=False
                    )
                    
                    return summary[0]['summary_text']
                    
                except Exception as e:
                    logger.warning(f"Erreur résumé Transformers: {e}")
            
            # Résumé extractif simple en fallback
            return self._extractive_summary(cleaned_text, max_length)
            
        except Exception as e:
            logger.error(f"Erreur génération résumé: {e}")
            return None
    
    def _clean_text(self, text: str) -> str:
        """
        Nettoyage du texte
        """
        # Suppression des caractères spéciaux excessifs
        text = re.sub(r'\s+', ' ', text)  # Espaces multiples
        text = re.sub(r'[^\w\sà-ÿ.,!?;:()\[\]-]', '', text)  # Caractères spéciaux
        return text.strip()
    
    def _classify_by_keywords(self, text: str) -> Dict[str, Any]:
        """
        Classification basique par mots-clés
        """
        text_lower = text.lower()
        scores = {}
        
        for category, info in self.document_categories.items():
            score = 0
            found_keywords = []
            
            for keyword in info['keywords']:
                count = text_lower.count(keyword.lower())
                if count > 0:
                    score += count
                    found_keywords.append(keyword)
            
            if score > 0:
                scores[category] = {
                    'score': score,
                    'keywords_found': found_keywords,
                    'description': info['description']
                }
        
        # Tri par score
        sorted_scores = sorted(scores.items(), key=lambda x: x[1]['score'], reverse=True)
        
        return {
            'top_category': sorted_scores[0][0] if sorted_scores else 'unknown',
            'all_scores': dict(sorted_scores),
            'confidence': sorted_scores[0][1]['score'] / len(text.split()) if sorted_scores else 0
        }
    
    def _analyze_content(self, text: str) -> Dict[str, Any]:
        """
        Analyse générale du contenu
        """
        words = word_tokenize(text.lower())
        sentences = sent_tokenize(text)
        
        # Statistiques basiques
        stats = {
            'word_count': len(words),
            'sentence_count': len(sentences),
            'avg_sentence_length': len(words) / len(sentences) if sentences else 0,
            'unique_words': len(set(words))
        }
        
        # Mots les plus fréquents
        try:
            stop_words = set(stopwords.words('french'))
            filtered_words = [word for word in words if word.isalpha() and word not in stop_words]
            most_common = Counter(filtered_words).most_common(10)
            stats['most_common_words'] = most_common
        except:
            stats['most_common_words'] = []
        
        return stats
    
    def _extract_named_entities(self, text: str) -> List[Dict[str, Any]]:
        """
        Extraction d'entités nommées basique
        """
        entities = []
        
        # Patterns pour entités françaises
        patterns = {
            'organization': r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+(?:SA|SARL|SAS|EURL|SNC)\b',
            'person': r'\b(?:M\.|Mme|Monsieur|Madame)\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b',
            'location': r'\b\d+[,\s]+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*[,\s]+\d{5}\s+[A-Z][a-z]+\b'
        }
        
        for entity_type, pattern in patterns.items():
            matches = re.finditer(pattern, text)
            for match in matches:
                entities.append({
                    'type': entity_type,
                    'value': match.group().strip(),
                    'start': match.start(),
                    'end': match.end(),
                    'confidence': 0.6
                })
        
        return entities
    
    def _deduplicate_entities(self, entities: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Suppression des doublons d'entités
        """
        seen = set()
        unique_entities = []
        
        for entity in entities:
            key = (entity['type'], entity['value'].lower())
            if key not in seen:
                seen.add(key)
                unique_entities.append(entity)
        
        return unique_entities
    
    def _extractive_summary(self, text: str, max_length: int) -> str:
        """
        Résumé extractif simple
        """
        sentences = sent_tokenize(text)
        
        if len(sentences) <= 3:
            return text
        
        # Sélection des premières phrases jusqu'à la limite
        summary_sentences = []
        current_length = 0
        
        for sentence in sentences:
            if current_length + len(sentence.split()) <= max_length:
                summary_sentences.append(sentence)
                current_length += len(sentence.split())
            else:
                break
        
        return ' '.join(summary_sentences)