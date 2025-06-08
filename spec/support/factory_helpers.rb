# Factory helpers for creating test data

module FactoryHelpers
  # Create a full organization with users and data
  def create_organization_with_data(name: "Test Organization", users_count: 3)
    organization = create(:organization, name: name)
    
    # Create admin user
    admin = create(:user, :admin, organization: organization)
    
    # Create regular users
    users = create_list(:user, users_count - 1, organization: organization)
    
    # Create spaces
    main_space = create(:space, name: "Main", organization: organization)
    archive_space = create(:space, name: "Archives", organization: organization)
    
    # Create folder structure
    root_folder = create(:folder, name: "Documents", space: main_space)
    contracts_folder = create(:folder, name: "Contracts", space: main_space, parent: root_folder)
    invoices_folder = create(:folder, name: "Invoices", space: main_space, parent: root_folder)
    
    # Create tags
    tags = %w[Important Urgent Finance HR Legal].map do |tag_name|
      create(:tag, name: tag_name, organization: organization)
    end
    
    # Create metadata template
    metadata_template = create(:metadata_template,
      name: "Standard Document",
      organization: organization,
      fields: [
        { name: "department", label: "Department", type: "string", required: true },
        { name: "year", label: "Year", type: "number", required: true },
        { name: "confidential", label: "Confidential", type: "boolean", required: false }
      ]
    )
    
    {
      organization: organization,
      admin: admin,
      users: [admin] + users,
      spaces: [main_space, archive_space],
      folders: {
        root: root_folder,
        contracts: contracts_folder,
        invoices: invoices_folder
      },
      tags: tags,
      metadata_template: metadata_template
    }
  end
  
  # Create a document with full setup
  def create_document_with_content(
    title: "Test Document",
    space: nil,
    folder: nil,
    user: nil,
    tags: [],
    metadata: {},
    file_type: :pdf
  )
    space ||= create(:space)
    user ||= create(:user, organization: space.organization)
    
    document = create(:document,
      title: title,
      space: space,
      folder: folder,
      user: user,
      processing_status: 'completed'
    )
    
    # Attach file
    file_path = case file_type
                when :pdf then "spec/fixtures/test_document.pdf"
                when :docx then "spec/fixtures/test_document.docx"
                when :image then "spec/fixtures/test_image.jpg"
                else "spec/fixtures/test_document.txt"
                end
    
    document.file.attach(
      io: File.open(Rails.root.join(file_path)),
      filename: "#{title.parameterize}.#{file_type}",
      content_type: content_type_for(file_type)
    )
    
    # Add tags
    document.tags << tags if tags.any?
    
    # Add metadata
    metadata.each do |key, value|
      document.metadata.create!(key: key.to_s, value: value.to_s)
    end
    
    # Generate preview for images
    if file_type == :image
      document.preview.attach(
        io: File.open(Rails.root.join("spec/fixtures/test_image_thumb.jpg")),
        filename: "#{title.parameterize}_thumb.jpg"
      )
    end
    
    document
  end
  
  # Create a user with specific permissions
  def create_user_with_permissions(*permissions, organization: nil)
    organization ||= create(:organization)
    user = create(:user, organization: organization)
    
    permissions.each do |permission|
      user.add_permission!(permission)
    end
    
    user
  end
  
  # Create a shared document setup
  def create_shared_document(owner:, recipients:, permission: 'read')
    document = create(:document, user: owner, space: owner.spaces.first)
    
    shares = recipients.map do |recipient|
      create(:document_share,
        document: document,
        shared_by: owner,
        shared_with: recipient,
        permission: permission
      )
    end
    
    { document: document, shares: shares }
  end
  
  # Create a project with full Immo::Promo setup
  def create_immo_promo_project(name: "Test Project", organization: nil)
    organization ||= create(:organization)
    
    project = create(:immo_promo_project,
      name: name,
      organization: organization,
      start_date: Date.today,
      end_date: 1.year.from_now
    )
    
    # Create default phases
    phases = [
      { name: "Études préliminaires", duration: 60 },
      { name: "Obtention des permis", duration: 90 },
      { name: "Travaux de construction", duration: 365 },
      { name: "Réception des travaux", duration: 30 },
      { name: "Livraison", duration: 15 }
    ].map.with_index do |phase_data, index|
      create(:immo_promo_phase,
        project: project,
        name: phase_data[:name],
        duration: phase_data[:duration],
        position: index + 1
      )
    end
    
    # Create stakeholders
    stakeholders = [
      { role: "architect", name: "Cabinet Architecture Plus" },
      { role: "contractor", name: "Construction Pro" },
      { role: "promoter", name: "Immobilier Dev" }
    ].map do |stakeholder_data|
      create(:immo_promo_stakeholder,
        project: project,
        role: stakeholder_data[:role],
        company_name: stakeholder_data[:name]
      )
    end
    
    # Create sample tasks
    tasks = phases.first(2).map do |phase|
      create_list(:immo_promo_task, 3,
        phase: phase,
        project: project,
        assigned_to: organization.users.sample
      )
    end.flatten
    
    {
      project: project,
      phases: phases,
      stakeholders: stakeholders,
      tasks: tasks
    }
  end
  
  # Create test data for search
  def create_searchable_documents(count: 10, space: nil)
    space ||= create(:space)
    
    document_types = %w[Contract Invoice Report Memo Presentation]
    departments = %w[Sales Marketing Finance HR IT]
    years = [2022, 2023, 2024]
    
    count.times.map do |i|
      doc_type = document_types.sample
      department = departments.sample
      year = years.sample
      
      create_document_with_content(
        title: "#{doc_type} #{department} #{year} ##{i}",
        space: space,
        tags: [doc_type.downcase, department.downcase].map { |t| 
          Tag.find_or_create_by(name: t, organization: space.organization)
        },
        metadata: {
          type: doc_type,
          department: department,
          year: year,
          reference: "#{doc_type[0..2].upcase}-#{year}-#{i.to_s.rjust(3, '0')}"
        }
      )
    end
  end
  
  # Create workflow with steps
  def create_workflow_with_steps(name: "Approval Workflow", organization: nil)
    organization ||= create(:organization)
    
    workflow = create(:workflow,
      name: name,
      organization: organization,
      active: true
    )
    
    steps = [
      { name: "Draft", position: 1, initial: true },
      { name: "Review", position: 2 },
      { name: "Approved", position: 3, final: true },
      { name: "Rejected", position: 4, final: true }
    ].map do |step_data|
      create(:workflow_step, workflow: workflow, **step_data)
    end
    
    # Create transitions
    transitions = [
      { from: steps[0], to: steps[1], action: "submit" },
      { from: steps[1], to: steps[2], action: "approve" },
      { from: steps[1], to: steps[3], action: "reject" },
      { from: steps[3], to: steps[0], action: "revise" }
    ].map do |transition_data|
      create(:workflow_transition, workflow: workflow, **transition_data)
    end
    
    { workflow: workflow, steps: steps, transitions: transitions }
  end
  
  private
  
  def content_type_for(file_type)
    {
      pdf: "application/pdf",
      docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      image: "image/jpeg",
      txt: "text/plain"
    }[file_type] || "application/octet-stream"
  end
end

RSpec.configure do |config|
  config.include FactoryHelpers
end