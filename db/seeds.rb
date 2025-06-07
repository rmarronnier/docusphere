# Création de l'organisation principale
organization = Organization.find_or_create_by(slug: "docusphere") do |org|
  org.name = "Docusphere"
end

# Création de l'utilisateur administrateur
admin = User.find_or_create_by(email: "admin@docusphere.fr") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.first_name = "Admin"
  user.last_name = "Système"
  user.organization = organization
  user.role = "admin"
end

# Création d'espaces par défaut
spaces_data = [
  { name: "Direction Générale", description: "Documents de la direction" },
  { name: "Ressources Humaines", description: "Documents RH" },
  { name: "Finance", description: "Documents financiers" },
  { name: "Projets", description: "Documents de projets" }
]

spaces_data.each do |space_data|
  Space.find_or_create_by(name: space_data[:name], organization: organization) do |space|
    space.description = space_data[:description]
    space.slug = space_data[:name].parameterize
  end
end

# Création de tags par défaut
%w[urgent important archive confidentiel validé brouillon].each do |tag_name|
  Tag.find_or_create_by(name: tag_name)
end

puts "Seeds créés avec succès !"
puts "Compte admin : admin@docusphere.fr / password123"