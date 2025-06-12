# Générateur de données réalistes pour les seeds
class RealisticDataGenerator
  # Entreprises françaises réalistes
  COMPANY_NAMES = [
    "Bouygues Construction", "Vinci Construction", "Eiffage Construction", "Spie Batignolles",
    "Nexity", "Kaufman & Broad", "Icade", "Altarea Cogedim", "BNP Paribas Real Estate",
    "Société Générale Real Estate", "AXA Real Estate", "Groupe Casino Immobilier",
    "Carrefour Property", "Unibail-Rodamco-Westfield", "Klépierre", "Gecina",
    "Foncière des Régions", "Mercialys", "Cegereal", "Société de la Tour Eiffel"
  ].freeze

  # Prénoms et noms français
  FIRST_NAMES = {
    male: %w[Pierre Jean François Michel Philippe Alain Bernard Laurent David Marc 
             Thomas Nicolas Olivier Patrick Daniel Jacques Christophe Sébastien 
             Guillaume Alexandre Julien Maxime Antoine Mathieu Vincent],
    female: %w[Marie Anne Sophie Claire Isabelle Catherine Nathalie Christine 
               Sandrine Sylvie Valérie Martine Hélène Céline Julie Emma 
               Chloé Léa Sarah Camille Laura Pauline Charlotte Alice]
  }.freeze

  LAST_NAMES = %w[
    Martin Bernard Dubois Thomas Robert Richard Petit Durand Leroy Moreau
    Simon Laurent Lefebvre Michel Garcia David Bertrand Roux Vincent
    Fournier Morel Girard Andre Mercier Dupont Lambert Bonnet François
    Martinez Legrand Garnier Faure Rousseau Blanc Guerin Muller Henry
    Roussel Nicolas Perrin Morin Mathieu Clement Gauthier Dumont Lopez
  ].freeze

  # Métiers et rôles professionnels
  JOB_TITLES = {
    direction: ["Directeur Général", "Directeur des Opérations", "Directeur Financier", 
                "Directeur Commercial", "Directeur Technique", "Directeur Juridique"],
    chef_projet: ["Chef de Projet", "Chef de Projet Senior", "Directeur de Programmes", 
                  "Responsable de Projet", "Coordinateur de Projet", "PMO"],
    architecte: ["Architecte en Chef", "Architecte Senior", "Architecte Junior", 
                 "Architecte Urbaniste", "Architecte d'Intérieur", "BIM Manager"],
    expert_technique: ["Ingénieur Structure", "Ingénieur Fluides", "Ingénieur VRD", 
                       "Ingénieur Électricité", "Ingénieur CVC", "Ingénieur Méthodes",
                       "Conducteur de Travaux", "Chef de Chantier", "Technicien Bureau d'Études"],
    commercial: ["Directeur Commercial", "Responsable Commercial", "Chargé d'Affaires", 
                 "Commercial Senior", "Business Developer", "Account Manager"],
    juriste: ["Juriste Construction", "Responsable Juridique", "Contract Manager", 
              "Juriste Immobilier", "Avocat Conseil", "Responsable Conformité"],
    controleur: ["Contrôleur de Gestion", "Analyste Financier", "Auditeur Interne", 
                 "Responsable Administratif", "Credit Manager", "Risk Manager"],
    assistant_rh: ["Assistant RH", "Chargé de Recrutement", "Gestionnaire Paie",
                   "Responsable Formation", "Chargé de Développement RH"],
    communication: ["Chargé de Communication", "Community Manager", "Responsable Marketing",
                    "Chef de Projet Digital", "Content Manager"],
    admin_system: ["Administrateur Système", "Chef de Projet IT", "DevOps",
                   "Responsable Infrastructure", "Architecte Technique"]
  }.freeze

  # Types de projets immobiliers
  PROJECT_TYPES = [
    { name: "Résidence Les Jardins de Belleville", type: "residential", city: "Paris", budget: 45_000_000 },
    { name: "Tour Horizon La Défense", type: "office", city: "Courbevoie", budget: 120_000_000 },
    { name: "Centre Commercial Grand Ouest", type: "commercial", city: "Nantes", budget: 85_000_000 },
    { name: "Écoquartier Les Rives de Seine", type: "mixed", city: "Boulogne-Billancourt", budget: 200_000_000 },
    { name: "Parc Logistique Sud", type: "industrial", city: "Lyon", budget: 35_000_000 },
    { name: "Résidence Étudiante Campus", type: "residential", city: "Toulouse", budget: 25_000_000 },
    { name: "Galerie Commerciale", type: "retail", city: "Paris", budget: 60_000_000 },
    { name: "Immeuble de Bureaux", type: "office", city: "Marseille", budget: 40_000_000 },
    { name: "Business Park Innovation", type: "office", city: "Sophia Antipolis", budget: 95_000_000 },
    { name: "Résidence Senior Les Oliviers", type: "residential", city: "Nice", budget: 30_000_000 }
  ].freeze

  # Descriptions de documents par catégorie
  DOCUMENT_DESCRIPTIONS = {
    permit: [
      "Permis de construire délivré par la mairie",
      "Autorisation de travaux en zone protégée",
      "Permis de démolir pour restructuration",
      "Déclaration préalable de travaux",
      "Arrêté municipal d'autorisation"
    ],
    contract: [
      "Contrat de maîtrise d'œuvre",
      "Contrat de construction clé en main",
      "Contrat de sous-traitance lot gros œuvre",
      "Contrat de promotion immobilière",
      "Contrat de vente en état futur d'achèvement"
    ],
    plan: [
      "Plans d'architecte niveau RDC",
      "Plans de structure béton armé",
      "Plans réseaux fluides et CVC",
      "Plans d'aménagement intérieur",
      "Plans de façade et coupes"
    ],
    report: [
      "Rapport d'avancement mensuel",
      "Compte-rendu de réunion de chantier",
      "Rapport d'expertise technique",
      "Rapport de conformité réglementaire",
      "Bilan financier trimestriel"
    ],
    technical: [
      "Note de calcul structure",
      "Étude géotechnique G2 PRO",
      "Diagnostic amiante avant travaux",
      "Étude thermique RT2012",
      "Cahier des charges techniques"
    ],
    financial: [
      "Budget prévisionnel détaillé",
      "Situation financière mensuelle",
      "Facture lot menuiserie extérieure",
      "Décompte général définitif",
      "Plan de financement bancaire"
    ],
    legal: [
      "Acte de vente terrain",
      "Protocole d'accord promoteur",
      "Convention de servitude",
      "Règlement de copropriété",
      "Attestation d'assurance décennale"
    ],
    quality: [
      "Plan Assurance Qualité chantier",
      "Procédure de contrôle béton",
      "Check-list réception travaux",
      "Rapport de non-conformité",
      "Certificat de conformité CE"
    ]
  }.freeze

  # Tags métier
  BUSINESS_TAGS = [
    "urgent", "confidentiel", "validation requise", "approuvé", "en révision",
    "draft", "final", "archivé", "phase conception", "phase exécution",
    "lot structure", "lot façade", "lot CVC", "lot électricité", "lot plomberie",
    "conformité", "sécurité", "environnement", "qualité", "délai critique"
  ].freeze

  # Métadonnées par type de document
  METADATA_TEMPLATES = {
    permit: {
      numero_dossier: -> { "PC#{rand(100000..999999)}" },
      date_depot: -> { rand(6.months.ago..1.month.ago) },
      date_obtention: -> { rand(1.month.ago..Date.today) },
      validite_annees: -> { [3, 5, 10].sample },
      surface_autorisee: -> { rand(500..5000) }
    },
    contract: {
      numero_contrat: -> { "CTR-#{Date.today.year}-#{rand(1000..9999)}" },
      montant_ht: -> { rand(100_000..10_000_000) },
      date_signature: -> { rand(3.months.ago..Date.today) },
      duree_mois: -> { [6, 12, 18, 24, 36].sample },
      penalites_retard: -> { [0.1, 0.2, 0.5, 1.0].sample }
    },
    plan: {
      version: -> { "V#{rand(1..5)}.#{rand(0..9)}" },
      echelle: -> { ["1:50", "1:100", "1:200", "1:500"].sample },
      format: -> { ["A0", "A1", "A2", "A3"].sample },
      logiciel: -> { ["AutoCAD", "Revit", "ArchiCAD", "SketchUp"].sample },
      derniere_modification: -> { rand(1.week.ago..Date.today) }
    },
    technical: {
      norme_reference: -> { ["NF DTU", "Eurocode", "RT2012", "RE2020"].sample },
      bureau_etude: -> { ["BET Structure Plus", "Fluides Conseil", "Thermique Expert"].sample },
      date_etude: -> { rand(6.months.ago..1.month.ago) },
      conclusions: -> { ["Conforme", "Conforme avec réserves", "Non conforme"].sample }
    }
  }.freeze

  class << self
    def generate_user
      gender = [:male, :female].sample
      first_name = FIRST_NAMES[gender].sample
      last_name = LAST_NAMES.sample
      
      {
        first_name: first_name,
        last_name: last_name,
        email: "#{first_name.downcase}.#{last_name.downcase}@#{generate_company_domain}",
        phone: generate_french_phone,
        mobile: generate_french_mobile,
        job_title: JOB_TITLES.values.flatten.sample,
        department: JOB_TITLES.keys.sample
      }
    end

    def generate_company_domain
      company = COMPANY_NAMES.sample.downcase.gsub(/[^a-z0-9]/, '')
      "#{company}.fr"
    end

    def generate_french_phone
      "01 #{rand(40..49)} #{rand(10..99)} #{rand(10..99)} #{rand(10..99)}"
    end

    def generate_french_mobile
      "06 #{rand(10..99)} #{rand(10..99)} #{rand(10..99)} #{rand(10..99)}"
    end

    def generate_project
      project = PROJECT_TYPES.sample.deep_dup
      project[:description] = generate_project_description(project)
      project[:start_date] = rand(1.year.ago..3.months.ago)
      project[:end_date] = project[:start_date] + rand(12..36).months
      project[:completion_percentage] = rand(10..95)
      project
    end

    def generate_project_description(project)
      "Projet de #{project[:type]} situé à #{project[:city]}. " \
      "Budget total: #{number_to_currency(project[:budget])}. " \
      "Surface: #{rand(1000..50000)}m². " \
      "#{rand(50..200)} lots. Livraison prévue #{(Date.today + rand(6..24).months).strftime('%B %Y')}."
    end

    def generate_document_name(category)
      base_names = {
        pdf: ["Rapport", "Document", "Dossier", "Étude", "Plan", "Note"],
        images: ["Photo", "Vue", "Plan", "Schéma", "Perspective", "Rendu"],
        text: ["Note", "Compte-rendu", "Procédure", "Checklist", "Mémo"],
        office: ["Tableau", "Planning", "Budget", "Analyse", "Présentation"],
        cad: ["Plan", "Coupe", "Façade", "Détail", "Assemblage", "Schéma"],
        videos: ["Visite", "Timelapse", "Présentation", "Formation", "Inspection"]
      }
      
      base = base_names[category]&.sample || "Document"
      suffix = ["", " #{Date.today.year}", " V#{rand(1..3)}", " - #{['Draft', 'Final', 'Révision'].sample}"].sample
      
      "#{base} #{PROJECT_TYPES.sample[:name].split(' ').first(2).join(' ')}#{suffix}"
    end

    def generate_document_description(category, name)
      templates = DOCUMENT_DESCRIPTIONS[category] || DOCUMENT_DESCRIPTIONS.values.flatten
      template = templates.sample
      
      "#{template}. Document créé pour #{PROJECT_TYPES.sample[:name]}. " \
      "Référence: #{generate_reference_number}. " \
      "#{['Document validé', 'En cours de validation', 'Pour information'].sample}."
    end

    def generate_reference_number
      prefix = ["REF", "DOC", "IMM", "TECH", "ADM"].sample
      "#{prefix}-#{Date.today.year}-#{rand(10000..99999)}"
    end

    def generate_tags(count = rand(2..5))
      BUSINESS_TAGS.sample(count)
    end

    def generate_metadata(document_type)
      template = METADATA_TEMPLATES[document_type] || {}
      metadata = {}
      
      template.each do |key, generator|
        metadata[key] = generator.call
      end
      
      # Ajouter des métadonnées communes
      metadata[:created_by] = generate_user[:first_name] + " " + generate_user[:last_name]
      metadata[:department] = JOB_TITLES.keys.sample.to_s
      metadata[:confidentiality] = ["public", "interne", "confidentiel", "secret"].sample
      metadata[:version] = "#{rand(1..3)}.#{rand(0..9)}"
      
      metadata
    end

    def generate_folder_structure
      {
        "Direction Générale" => ["Stratégie", "Rapports CA", "Audits", "Conformité"],
        "Projets" => PROJECT_TYPES.map { |p| p[:name] },
        "Commercial" => ["Propositions", "Contrats", "Clients", "Prospects"],
        "Technique" => ["Plans", "Études", "Normes", "Procédures"],
        "Juridique" => ["Contrats", "Contentieux", "Propriété", "Assurances"],
        "Finance" => ["Budgets", "Factures", "Rapports", "Trésorerie"],
        "RH" => ["Recrutement", "Formation", "Paie", "Procédures"],
        "Qualité" => ["Certifications", "Audits", "Non-conformités", "Amélioration"],
        "HSE" => ["Sécurité", "Environnement", "Prévention", "Incidents"],
        "Archives" => ["2021", "2022", "2023", "Projets terminés"]
      }
    end

    private

    def number_to_currency(amount)
      "#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1 ').reverse} €"
    end
  end
end