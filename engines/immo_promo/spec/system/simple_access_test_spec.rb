require 'rails_helper'

RSpec.describe "Simple Access Test", type: :system do
  let(:organization) { create(:organization, name: "Test-#{SecureRandom.hex(4)}") }
  
  let(:controller_user) {
    create(:user,
      email: "test-controle@test.fr",
      password: "password123",
      password_confirmation: "password123",
      role: "manager",
      organization: organization,
      permissions: { 'immo_promo:access' => true }
    )
  }
  
  let!(:project) {
    create(:immo_promo_project,
      name: "Test Project Access",
      organization: organization
    )
  }

  before do
    # Ensure the user and project exist
    controller_user.reload
    project.reload
  end

  it "allows controller user to access project details", js: true do
    puts "\n🔍 Debugging access test..."
    puts "   User: #{controller_user.email}"
    puts "   User permissions: #{controller_user.permissions}"
    puts "   Project: #{project.name}"
    puts "   Same org: #{controller_user.organization.id == project.organization.id}"
    
    # Test policy directly
    policy = Immo::Promo::ProjectPolicy.new(controller_user, project)
    puts "   Policy index?: #{policy.index?}"
    puts "   Policy show?: #{policy.show?}"
    
    # Test scope
    scope = Immo::Promo::ProjectPolicy::Scope.new(controller_user, Immo::Promo::Project).resolve
    puts "   Scope count: #{scope.count}"
    puts "   Project in scope: #{scope.where(id: project.id).exists?}"
    
    login_as(controller_user, scope: :user)
    
    # Test access to projects index
    visit "/immo/promo/projects"
    
    puts "   Page title: #{page.title}"
    puts "   Current path: #{current_path}"
    puts "   Page has project name: #{page.has_content?(project.name)}"
    
    expect(page).to have_content("Test Project Access")
    
    # Test access to project details
    visit "/immo/promo/projects/#{project.id}"
    
    puts "   Detail page title: #{page.title}"
    puts "   Detail current path: #{current_path}"
    puts "   Detail page content check: #{page.has_content?(project.name)}"
    
    expect(page).to have_content("Test Project Access")
    expect(page).not_to have_content("Accès non autorisé")
    expect(page).not_to have_content("pas les droits")
  end
end