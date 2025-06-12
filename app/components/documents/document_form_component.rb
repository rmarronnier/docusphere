class Documents::DocumentFormComponent < ApplicationComponent
  attr_reader :document, :metadata_template, :allowed_file_types, :max_file_size,
              :enable_tags, :allow_new_tags, :show_permissions, :show_advanced_options,
              :show_save_and_continue

  def initialize(document:, metadata_template: nil, allowed_file_types: nil, 
                 max_file_size: 100.megabytes, enable_tags: true, allow_new_tags: true,
                 show_permissions: false, show_advanced_options: false, 
                 show_save_and_continue: false)
    @document = document
    @metadata_template = metadata_template
    @allowed_file_types = allowed_file_types
    @max_file_size = max_file_size
    @enable_tags = enable_tags
    @allow_new_tags = allow_new_tags
    @show_permissions = show_permissions
    @show_advanced_options = show_advanced_options
    @show_save_and_continue = show_save_and_continue
  end

  def form_url
    document.persisted? ? helpers.ged_document_path(document) : helpers.ged_upload_document_path
  end

  def form_method
    document.persisted? ? :patch : :post
  end

  def submit_button_text
    document.persisted? ? "Mettre à jour" : "Créer"
  end

  def spaces_for_select
    helpers.policy_scope(Space).pluck(:name, :id)
  end

  def folders_for_select
    return [] unless document.space
    
    folders = helpers.policy_scope(Folder).where(space: document.space)
    folders.map do |folder|
      [folder_path_name(folder), folder.id]
    end
  end

  def existing_tags
    helpers.policy_scope(Tag).pluck(:name)
  end

  private

  def folder_path_name(folder)
    path = [folder.name]
    parent = folder.parent
    while parent
      path.unshift(parent.name)
      parent = parent.parent
    end
    path.join(" / ")
  end
end