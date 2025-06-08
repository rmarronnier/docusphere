# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_06_08_211529) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "authorizations", force: :cascade do |t|
    t.string "authorizable_type", null: false
    t.bigint "authorizable_id", null: false
    t.bigint "user_id"
    t.bigint "user_group_id"
    t.string "permission_level", null: false
    t.bigint "granted_by_id"
    t.bigint "revoked_by_id"
    t.datetime "granted_at"
    t.datetime "revoked_at"
    t.datetime "expires_at"
    t.text "comment"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authorizable_type", "authorizable_id"], name: "index_authorizations_on_authorizable"
    t.index ["authorizable_type", "authorizable_id"], name: "index_authorizations_on_authorizable_type_and_authorizable_id"
    t.index ["expires_at"], name: "index_authorizations_on_expires_at"
    t.index ["granted_by_id"], name: "index_authorizations_on_granted_by_id"
    t.index ["is_active"], name: "index_authorizations_on_is_active"
    t.index ["permission_level"], name: "index_authorizations_on_permission_level"
    t.index ["revoked_by_id"], name: "index_authorizations_on_revoked_by_id"
    t.index ["user_group_id"], name: "index_authorizations_on_user_group_id"
    t.index ["user_id"], name: "index_authorizations_on_user_id"
    t.check_constraint "user_id IS NOT NULL AND user_group_id IS NULL OR user_id IS NULL AND user_group_id IS NOT NULL", name: "check_user_or_group_present"
  end

  create_table "basket_items", force: :cascade do |t|
    t.bigint "basket_id", null: false
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.integer "position"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["basket_id", "item_type", "item_id"], name: "index_basket_items_on_basket_id_and_item_type_and_item_id", unique: true
    t.index ["basket_id"], name: "index_basket_items_on_basket_id"
    t.index ["item_type", "item_id"], name: "index_basket_items_on_item"
    t.index ["item_type", "item_id"], name: "index_basket_items_on_item_type_and_item_id"
    t.index ["position"], name: "index_basket_items_on_position"
  end

  create_table "baskets", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "user_id", null: false
    t.string "basket_type", default: "personal"
    t.boolean "is_shared", default: false
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["basket_type"], name: "index_baskets_on_basket_type"
    t.index ["is_shared"], name: "index_baskets_on_is_shared"
    t.index ["user_id"], name: "index_baskets_on_user_id"
  end

  create_table "document_metadata", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "metadata_template_id", null: false
    t.jsonb "values", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "metadata_template_id"], name: "idx_on_document_id_metadata_template_id_bdac7c629b", unique: true
    t.index ["document_id"], name: "index_document_metadata_on_document_id"
    t.index ["metadata_template_id"], name: "index_document_metadata_on_metadata_template_id"
  end

  create_table "document_shares", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "shared_by_id", null: false
    t.bigint "shared_with_id"
    t.string "email"
    t.string "access_level", default: "read"
    t.datetime "expires_at"
    t.string "access_token"
    t.integer "access_count", default: 0
    t.datetime "last_accessed_at"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_document_shares_on_access_token", unique: true
    t.index ["document_id"], name: "index_document_shares_on_document_id"
    t.index ["expires_at"], name: "index_document_shares_on_expires_at"
    t.index ["is_active"], name: "index_document_shares_on_is_active"
    t.index ["shared_by_id"], name: "index_document_shares_on_shared_by_id"
    t.index ["shared_with_id"], name: "index_document_shares_on_shared_with_id"
  end

  create_table "document_tags", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "tag_id"], name: "index_document_tags_on_document_id_and_tag_id", unique: true
    t.index ["document_id"], name: "index_document_tags_on_document_id"
    t.index ["tag_id"], name: "index_document_tags_on_tag_id"
  end

  create_table "document_validations", force: :cascade do |t|
    t.bigint "validation_request_id", null: false
    t.bigint "document_id", null: false
    t.bigint "validator_id", null: false
    t.string "status", default: "pending"
    t.text "comment"
    t.datetime "validated_at"
    t.jsonb "validation_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_document_validations_on_document_id"
    t.index ["status"], name: "index_document_validations_on_status"
    t.index ["validated_at"], name: "index_document_validations_on_validated_at"
    t.index ["validation_request_id", "validator_id"], name: "idx_unique_validator_per_request", unique: true
    t.index ["validation_request_id"], name: "index_document_validations_on_validation_request_id"
    t.index ["validator_id"], name: "index_document_validations_on_validator_id"
  end

  create_table "document_versions", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.integer "version_number", null: false
    t.bigint "uploaded_by_id", null: false
    t.text "changes_description"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "version_number"], name: "index_document_versions_on_document_id_and_version_number", unique: true
    t.index ["document_id"], name: "index_document_versions_on_document_id"
    t.index ["uploaded_by_id"], name: "index_document_versions_on_uploaded_by_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.bigint "folder_id"
    t.bigint "space_id", null: false
    t.bigint "parent_id"
    t.bigint "uploaded_by_id", null: false
    t.string "document_type"
    t.string "status", default: "draft"
    t.jsonb "metadata", default: {}
    t.integer "file_size"
    t.string "content_type"
    t.string "file_name"
    t.datetime "archived_at"
    t.boolean "is_template", default: false
    t.string "external_id"
    t.datetime "expires_at"
    t.boolean "is_public", default: false
    t.integer "download_count", default: 0
    t.integer "view_count", default: 0
    t.string "processing_status", default: "pending"
    t.string "virus_scan_status", default: "pending"
    t.text "content"
    t.datetime "ai_processed_at"
    t.string "ai_category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "processing_started_at"
    t.datetime "processing_completed_at"
    t.text "processing_error"
    t.jsonb "processing_metadata", default: {}
    t.text "extracted_content"
    t.index ["archived_at"], name: "index_documents_on_archived_at"
    t.index ["document_type"], name: "index_documents_on_document_type"
    t.index ["expires_at"], name: "index_documents_on_expires_at"
    t.index ["external_id"], name: "index_documents_on_external_id"
    t.index ["folder_id"], name: "index_documents_on_folder_id"
    t.index ["is_public"], name: "index_documents_on_is_public"
    t.index ["is_template"], name: "index_documents_on_is_template"
    t.index ["parent_id"], name: "index_documents_on_parent_id"
    t.index ["processing_completed_at"], name: "index_documents_on_processing_completed_at"
    t.index ["processing_started_at"], name: "index_documents_on_processing_started_at"
    t.index ["processing_status"], name: "index_documents_on_processing_status"
    t.index ["space_id"], name: "index_documents_on_space_id"
    t.index ["status"], name: "index_documents_on_status"
    t.index ["uploaded_by_id"], name: "index_documents_on_uploaded_by_id"
    t.index ["virus_scan_status"], name: "index_documents_on_virus_scan_status"
  end

  create_table "folders", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "space_id", null: false
    t.bigint "parent_id"
    t.string "slug"
    t.string "path"
    t.integer "position"
    t.jsonb "metadata", default: {}
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_folders_on_is_active"
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["path"], name: "index_folders_on_path"
    t.index ["position"], name: "index_folders_on_position"
    t.index ["slug"], name: "index_folders_on_slug"
    t.index ["space_id"], name: "index_folders_on_space_id"
  end

  create_table "immo_promo_budget_lines", force: :cascade do |t|
    t.bigint "budget_id", null: false
    t.string "category"
    t.string "subcategory"
    t.string "description"
    t.integer "planned_amount_cents"
    t.integer "actual_amount_cents"
    t.integer "committed_amount_cents"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id"], name: "index_immo_promo_budget_lines_on_budget_id"
    t.index ["category"], name: "index_immo_promo_budget_lines_on_category"
    t.index ["subcategory"], name: "index_immo_promo_budget_lines_on_subcategory"
  end

  create_table "immo_promo_budgets", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.integer "fiscal_year"
    t.integer "total_amount_cents"
    t.string "status", default: "draft"
    t.date "approved_date"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "budget_type", default: "initial"
    t.string "version"
    t.integer "spent_amount_cents"
    t.boolean "is_current", default: false
    t.index ["approved_by_id"], name: "index_immo_promo_budgets_on_approved_by_id"
    t.index ["project_id"], name: "index_immo_promo_budgets_on_project_id"
    t.index ["status"], name: "index_immo_promo_budgets_on_status"
  end

  create_table "immo_promo_certifications", force: :cascade do |t|
    t.bigint "stakeholder_id", null: false
    t.string "name"
    t.string "issuing_body"
    t.date "issue_date"
    t.date "expiry_date"
    t.boolean "is_verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "certification_type"
    t.boolean "is_valid", default: true
    t.index ["stakeholder_id"], name: "index_immo_promo_certifications_on_stakeholder_id"
  end

  create_table "immo_promo_contracts", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "stakeholder_id"
    t.string "contract_type"
    t.string "contract_number"
    t.string "status", default: "draft"
    t.date "start_date"
    t.date "end_date"
    t.integer "amount_cents"
    t.string "currency", default: "EUR"
    t.string "payment_terms"
    t.text "description"
    t.date "signed_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "terms"
    t.integer "paid_amount_cents"
    t.index ["contract_number"], name: "index_immo_promo_contracts_on_contract_number"
    t.index ["contract_type"], name: "index_immo_promo_contracts_on_contract_type"
    t.index ["project_id"], name: "index_immo_promo_contracts_on_project_id"
    t.index ["stakeholder_id"], name: "index_immo_promo_contracts_on_stakeholder_id"
    t.index ["status"], name: "index_immo_promo_contracts_on_status"
  end

  create_table "immo_promo_lot_specifications", force: :cascade do |t|
    t.bigint "lot_id", null: false
    t.integer "rooms"
    t.integer "bedrooms"
    t.integer "bathrooms"
    t.boolean "has_balcony", default: false
    t.boolean "has_terrace", default: false
    t.boolean "has_parking", default: false
    t.boolean "has_storage", default: false
    t.string "energy_class"
    t.boolean "accessibility_features", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.index ["lot_id"], name: "index_immo_promo_lot_specifications_on_lot_id"
  end

  create_table "immo_promo_lots", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "lot_number", null: false
    t.string "lot_type"
    t.integer "floor"
    t.string "building"
    t.decimal "surface_area"
    t.integer "rooms_count"
    t.integer "price_cents"
    t.string "status", default: "available"
    t.string "orientation"
    t.jsonb "features", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price"
    t.index ["lot_type"], name: "index_immo_promo_lots_on_lot_type"
    t.index ["project_id", "lot_number"], name: "index_immo_promo_lots_on_project_id_and_lot_number", unique: true
    t.index ["project_id"], name: "index_immo_promo_lots_on_project_id"
    t.index ["status"], name: "index_immo_promo_lots_on_status"
  end

  create_table "immo_promo_milestones", force: :cascade do |t|
    t.bigint "phase_id", null: false
    t.string "name", null: false
    t.text "description"
    t.date "target_date"
    t.date "actual_date"
    t.string "status", default: "pending"
    t.boolean "is_critical", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "milestone_type"
    t.datetime "completed_at"
    t.index ["phase_id"], name: "index_immo_promo_milestones_on_phase_id"
    t.index ["status"], name: "index_immo_promo_milestones_on_status"
    t.index ["target_date"], name: "index_immo_promo_milestones_on_target_date"
  end

  create_table "immo_promo_permit_conditions", force: :cascade do |t|
    t.bigint "permit_id", null: false
    t.text "description"
    t.string "compliance_status", default: "pending"
    t.date "due_date"
    t.date "compliance_date"
    t.text "compliance_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending"
    t.string "condition_type"
    t.boolean "is_fulfilled", default: false
    t.date "met_date"
    t.index ["permit_id"], name: "index_immo_promo_permit_conditions_on_permit_id"
  end

  create_table "immo_promo_permits", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "permit_type", null: false
    t.string "permit_number"
    t.string "status", default: "pending"
    t.date "application_date"
    t.date "submitted_date"
    t.date "approval_date"
    t.date "approved_date"
    t.date "expiry_date"
    t.string "issuing_authority"
    t.text "conditions"
    t.text "notes"
    t.jsonb "documents", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "submitted_by_id"
    t.bigint "approved_by_id"
    t.string "title"
    t.string "reference"
    t.integer "fee_amount_cents"
    t.text "description"
    t.string "name"
    t.decimal "cost", precision: 10, scale: 2
    t.date "expected_approval_date"
    t.index ["approved_by_id"], name: "index_immo_promo_permits_on_approved_by_id"
    t.index ["permit_number"], name: "index_immo_promo_permits_on_permit_number"
    t.index ["permit_type"], name: "index_immo_promo_permits_on_permit_type"
    t.index ["project_id"], name: "index_immo_promo_permits_on_project_id"
    t.index ["status"], name: "index_immo_promo_permits_on_status"
    t.index ["submitted_by_id"], name: "index_immo_promo_permits_on_submitted_by_id"
  end

  create_table "immo_promo_phase_dependencies", force: :cascade do |t|
    t.bigint "dependent_phase_id", null: false
    t.bigint "prerequisite_phase_id", null: false
    t.string "dependency_type", default: "finish_to_start"
    t.integer "lag_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dependent_phase_id", "prerequisite_phase_id"], name: "idx_phase_dependencies_unique", unique: true
    t.index ["dependent_phase_id"], name: "index_immo_promo_phase_dependencies_on_dependent_phase_id"
    t.index ["prerequisite_phase_id"], name: "index_immo_promo_phase_dependencies_on_prerequisite_phase_id"
  end

  create_table "immo_promo_phases", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "responsible_user_id"
    t.string "name", null: false
    t.text "description"
    t.string "phase_type", default: "studies"
    t.integer "position"
    t.string "status", default: "pending"
    t.date "start_date"
    t.date "end_date"
    t.integer "budget_cents"
    t.integer "actual_cost_cents"
    t.decimal "progress_percentage", default: "0.0"
    t.boolean "is_critical", default: false
    t.jsonb "deliverables", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "deliverables_count", default: 0
    t.date "actual_start_date"
    t.date "actual_end_date"
    t.index ["phase_type"], name: "index_immo_promo_phases_on_phase_type"
    t.index ["project_id", "position"], name: "index_immo_promo_phases_on_project_id_and_position", unique: true
    t.index ["project_id"], name: "index_immo_promo_phases_on_project_id"
    t.index ["responsible_user_id"], name: "index_immo_promo_phases_on_responsible_user_id"
    t.index ["status"], name: "index_immo_promo_phases_on_status"
  end

  create_table "immo_promo_progress_reports", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "prepared_by_id", null: false
    t.date "report_date"
    t.date "period_start"
    t.date "period_end"
    t.decimal "overall_progress"
    t.decimal "budget_consumed"
    t.text "key_achievements"
    t.text "issues_risks"
    t.text "next_period_goals"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prepared_by_id"], name: "index_immo_promo_progress_reports_on_prepared_by_id"
    t.index ["project_id"], name: "index_immo_promo_progress_reports_on_project_id"
    t.index ["report_date"], name: "index_immo_promo_progress_reports_on_report_date"
  end

  create_table "immo_promo_projects", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.bigint "organization_id", null: false
    t.bigint "project_manager_id"
    t.string "reference_number"
    t.string "project_type"
    t.string "status", default: "planning"
    t.string "address"
    t.string "city"
    t.string "postal_code"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.decimal "total_area"
    t.decimal "land_area"
    t.decimal "buildable_surface_area"
    t.integer "total_units"
    t.date "start_date"
    t.date "expected_completion_date"
    t.date "actual_end_date"
    t.string "building_permit_number"
    t.integer "total_budget_cents"
    t.integer "current_budget_cents"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "slug"], name: "index_immo_promo_projects_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_immo_promo_projects_on_organization_id"
    t.index ["project_manager_id"], name: "index_immo_promo_projects_on_project_manager_id"
    t.index ["project_type"], name: "index_immo_promo_projects_on_project_type"
    t.index ["reference_number"], name: "index_immo_promo_projects_on_reference_number", unique: true
    t.index ["status"], name: "index_immo_promo_projects_on_status"
  end

  create_table "immo_promo_reservations", force: :cascade do |t|
    t.bigint "lot_id", null: false
    t.string "client_name", null: false
    t.string "client_email"
    t.string "client_phone"
    t.date "reservation_date"
    t.date "expiry_date"
    t.integer "deposit_amount_cents"
    t.string "status", default: "active"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lot_id"], name: "index_immo_promo_reservations_on_lot_id"
    t.index ["reservation_date"], name: "index_immo_promo_reservations_on_reservation_date"
    t.index ["status"], name: "index_immo_promo_reservations_on_status"
  end

  create_table "immo_promo_risks", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "category"
    t.string "probability"
    t.string "impact"
    t.integer "risk_score"
    t.string "status", default: "active"
    t.text "mitigation_plan"
    t.bigint "owner_id"
    t.date "identified_date"
    t.date "target_resolution_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_immo_promo_risks_on_category"
    t.index ["owner_id"], name: "index_immo_promo_risks_on_owner_id"
    t.index ["project_id"], name: "index_immo_promo_risks_on_project_id"
    t.index ["risk_score"], name: "index_immo_promo_risks_on_risk_score"
    t.index ["status"], name: "index_immo_promo_risks_on_status"
  end

  create_table "immo_promo_stakeholders", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.string "stakeholder_type"
    t.string "contact_person"
    t.string "email"
    t.string "phone"
    t.text "address"
    t.text "notes"
    t.string "specialization"
    t.boolean "is_active", default: true
    t.string "role"
    t.string "company_name"
    t.string "siret"
    t.boolean "is_primary", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_immo_promo_stakeholders_on_project_id"
    t.index ["role"], name: "index_immo_promo_stakeholders_on_role"
  end

  create_table "immo_promo_task_dependencies", force: :cascade do |t|
    t.bigint "dependent_task_id", null: false
    t.bigint "prerequisite_task_id", null: false
    t.string "dependency_type", default: "finish_to_start"
    t.integer "lag_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dependent_task_id", "prerequisite_task_id"], name: "idx_task_dependencies_unique", unique: true
    t.index ["dependent_task_id"], name: "index_immo_promo_task_dependencies_on_dependent_task_id"
    t.index ["prerequisite_task_id"], name: "index_immo_promo_task_dependencies_on_prerequisite_task_id"
  end

  create_table "immo_promo_tasks", force: :cascade do |t|
    t.bigint "phase_id", null: false
    t.bigint "assigned_to_id"
    t.bigint "stakeholder_id"
    t.string "name", null: false
    t.text "description"
    t.string "task_type", default: "technical"
    t.string "status", default: "pending"
    t.string "priority", default: "medium"
    t.date "start_date"
    t.date "end_date"
    t.date "completed_date"
    t.decimal "estimated_hours"
    t.decimal "actual_hours"
    t.integer "estimated_cost_cents"
    t.integer "actual_cost_cents"
    t.decimal "progress_percentage", default: "0.0"
    t.jsonb "checklist", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "actual_start_date"
    t.date "actual_end_date"
    t.datetime "completed_at"
    t.index ["assigned_to_id"], name: "index_immo_promo_tasks_on_assigned_to_id"
    t.index ["end_date"], name: "index_immo_promo_tasks_on_end_date"
    t.index ["phase_id"], name: "index_immo_promo_tasks_on_phase_id"
    t.index ["priority"], name: "index_immo_promo_tasks_on_priority"
    t.index ["stakeholder_id"], name: "index_immo_promo_tasks_on_stakeholder_id"
    t.index ["status"], name: "index_immo_promo_tasks_on_status"
    t.index ["task_type"], name: "index_immo_promo_tasks_on_task_type"
  end

  create_table "immo_promo_time_logs", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "user_id", null: false
    t.date "logged_date"
    t.decimal "hours", precision: 5, scale: 2
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["logged_date"], name: "index_immo_promo_time_logs_on_logged_date"
    t.index ["task_id"], name: "index_immo_promo_time_logs_on_task_id"
    t.index ["user_id"], name: "index_immo_promo_time_logs_on_user_id"
  end

  create_table "links", force: :cascade do |t|
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.string "link_type"
    t.text "description"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link_type"], name: "index_links_on_link_type"
    t.index ["source_type", "source_id"], name: "index_links_on_source"
    t.index ["source_type", "source_id"], name: "index_links_on_source_type_and_source_id"
    t.index ["target_type", "target_id"], name: "index_links_on_target"
    t.index ["target_type", "target_id"], name: "index_links_on_target_type_and_target_id"
  end

  create_table "metadata", force: :cascade do |t|
    t.string "metadatable_type", null: false
    t.bigint "metadatable_id", null: false
    t.string "key"
    t.text "value"
    t.bigint "metadata_field_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata_field_id"], name: "index_metadata_on_metadata_field_id"
    t.index ["metadatable_type", "metadatable_id", "key"], name: "idx_metadata_unique_key", unique: true, where: "(metadata_field_id IS NULL)"
    t.index ["metadatable_type", "metadatable_id", "metadata_field_id"], name: "idx_metadata_unique_field", unique: true, where: "(metadata_field_id IS NOT NULL)"
    t.index ["metadatable_type", "metadatable_id"], name: "index_metadata_on_metadatable"
  end

  create_table "metadata_fields", force: :cascade do |t|
    t.bigint "metadata_template_id", null: false
    t.string "name", null: false
    t.string "field_type", null: false
    t.string "label"
    t.text "description"
    t.boolean "required", default: false
    t.jsonb "options", default: {}
    t.jsonb "validation_rules", default: {}
    t.integer "position"
    t.string "default_value"
    t.boolean "is_searchable", default: false
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_type"], name: "index_metadata_fields_on_field_type"
    t.index ["is_active"], name: "index_metadata_fields_on_is_active"
    t.index ["is_searchable"], name: "index_metadata_fields_on_is_searchable"
    t.index ["metadata_template_id", "name"], name: "index_metadata_fields_on_metadata_template_id_and_name", unique: true
    t.index ["metadata_template_id"], name: "index_metadata_fields_on_metadata_template_id"
    t.index ["position"], name: "index_metadata_fields_on_position"
  end

  create_table "metadata_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "organization_id", null: false
    t.string "applicable_to"
    t.jsonb "structure", default: {}
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["applicable_to"], name: "index_metadata_templates_on_applicable_to"
    t.index ["is_active"], name: "index_metadata_templates_on_is_active"
    t.index ["organization_id", "name"], name: "index_metadata_templates_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_metadata_templates_on_organization_id"
  end

  create_table "metadatum", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "key"], name: "index_metadatum_on_document_id_and_key", unique: true
    t.index ["document_id"], name: "index_metadatum_on_document_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notification_type"
    t.string "title"
    t.text "message"
    t.jsonb "data", default: {}
    t.datetime "read_at"
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.jsonb "settings", default: {}
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_organizations_on_is_active"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "project_workflow_steps", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "sequence_number", null: false
    t.boolean "requires_approval", default: false
    t.boolean "is_active", default: true
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "workflowable_type"
    t.bigint "workflowable_id"
    t.index ["is_active"], name: "index_project_workflow_steps_on_is_active"
    t.index ["organization_id", "sequence_number"], name: "idx_on_organization_id_sequence_number_d640298ebc", unique: true
    t.index ["organization_id"], name: "index_project_workflow_steps_on_organization_id"
    t.index ["workflowable_type", "workflowable_id"], name: "index_project_workflow_steps_on_workflowable"
  end

  create_table "project_workflow_transitions", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "from_step_id"
    t.bigint "to_step_id", null: false
    t.bigint "transitioned_by_id", null: false
    t.text "notes"
    t.datetime "transitioned_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "workflowable_type"
    t.bigint "workflowable_id"
    t.index ["from_step_id"], name: "index_project_workflow_transitions_on_from_step_id"
    t.index ["project_id"], name: "index_project_workflow_transitions_on_project_id"
    t.index ["to_step_id"], name: "index_project_workflow_transitions_on_to_step_id"
    t.index ["transitioned_at"], name: "index_project_workflow_transitions_on_transitioned_at"
    t.index ["transitioned_by_id"], name: "index_project_workflow_transitions_on_transitioned_by_id"
    t.index ["workflowable_type", "workflowable_id"], name: "index_project_workflow_transitions_on_workflowable"
  end

  create_table "search_queries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.jsonb "query_params", default: {}
    t.integer "usage_count", default: 0
    t.datetime "last_used_at"
    t.boolean "is_favorite", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_favorite"], name: "index_search_queries_on_is_favorite"
    t.index ["last_used_at"], name: "index_search_queries_on_last_used_at"
    t.index ["usage_count"], name: "index_search_queries_on_usage_count"
    t.index ["user_id"], name: "index_search_queries_on_user_id"
  end

  create_table "shares", force: :cascade do |t|
    t.string "shareable_type", null: false
    t.bigint "shareable_id", null: false
    t.bigint "shared_by_id", null: false
    t.bigint "shared_with_id"
    t.bigint "shared_with_group_id"
    t.string "email"
    t.string "access_level", default: "read"
    t.datetime "expires_at"
    t.string "access_token"
    t.boolean "is_active", default: true
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_shares_on_access_token", unique: true
    t.index ["expires_at"], name: "index_shares_on_expires_at"
    t.index ["is_active"], name: "index_shares_on_is_active"
    t.index ["shareable_type", "shareable_id"], name: "index_shares_on_shareable"
    t.index ["shareable_type", "shareable_id"], name: "index_shares_on_shareable_type_and_shareable_id"
    t.index ["shared_by_id"], name: "index_shares_on_shared_by_id"
    t.index ["shared_with_group_id"], name: "index_shares_on_shared_with_group_id"
    t.index ["shared_with_id"], name: "index_shares_on_shared_with_id"
  end

  create_table "spaces", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.bigint "organization_id", null: false
    t.jsonb "settings", default: {}
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_spaces_on_is_active"
    t.index ["organization_id", "name"], name: "index_spaces_on_organization_id_and_name", unique: true
    t.index ["organization_id", "slug"], name: "index_spaces_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_spaces_on_organization_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "color"
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_tags_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_tags_on_organization_id"
  end

  create_table "user_features", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "feature_key", null: false
    t.boolean "enabled", default: false
    t.jsonb "settings", default: {}
    t.datetime "enabled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_user_features_on_enabled"
    t.index ["feature_key"], name: "index_user_features_on_feature_key"
    t.index ["user_id", "feature_key"], name: "index_user_features_on_user_id_and_feature_key", unique: true
    t.index ["user_id"], name: "index_user_features_on_user_id"
  end

  create_table "user_group_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "user_group_id", null: false
    t.string "role", default: "member"
    t.datetime "joined_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role"], name: "index_user_group_memberships_on_role"
    t.index ["user_group_id"], name: "index_user_group_memberships_on_user_group_id"
    t.index ["user_id", "user_group_id"], name: "index_user_group_memberships_on_user_id_and_user_group_id", unique: true
    t.index ["user_id"], name: "index_user_group_memberships_on_user_id"
  end

  create_table "user_groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.bigint "organization_id", null: false
    t.string "group_type"
    t.boolean "is_active", default: true
    t.jsonb "permissions", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_type"], name: "index_user_groups_on_group_type"
    t.index ["is_active"], name: "index_user_groups_on_is_active"
    t.index ["organization_id", "name"], name: "index_user_groups_on_organization_id_and_name", unique: true
    t.index ["organization_id", "slug"], name: "index_user_groups_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_user_groups_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.bigint "organization_id", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "role", default: "user", null: false
    t.jsonb "permissions", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "validation_requests", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "requester_id", null: false
    t.bigint "validation_template_id"
    t.integer "min_validations", default: 1
    t.string "status", default: "pending"
    t.text "description"
    t.datetime "due_date"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_validation_requests_on_completed_at"
    t.index ["document_id"], name: "index_validation_requests_on_document_id"
    t.index ["due_date"], name: "index_validation_requests_on_due_date"
    t.index ["requester_id"], name: "index_validation_requests_on_requester_id"
    t.index ["status"], name: "index_validation_requests_on_status"
    t.index ["validation_template_id"], name: "index_validation_requests_on_validation_template_id"
  end

  create_table "validation_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "organization_id", null: false
    t.string "applicable_to"
    t.integer "min_validators", default: 1
    t.jsonb "validation_rules", default: {}
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["applicable_to"], name: "index_validation_templates_on_applicable_to"
    t.index ["is_active"], name: "index_validation_templates_on_is_active"
    t.index ["organization_id", "name"], name: "index_validation_templates_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_validation_templates_on_organization_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.text "object_changes"
    t.datetime "created_at"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["event"], name: "index_versions_on_event"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  create_table "workflow_steps", force: :cascade do |t|
    t.bigint "workflow_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "position", null: false
    t.string "step_type"
    t.jsonb "settings", default: {}
    t.string "status", default: "pending"
    t.bigint "assigned_to_id"
    t.bigint "assigned_to_group_id"
    t.datetime "due_date"
    t.string "priority"
    t.jsonb "validation_rules", default: {}
    t.boolean "requires_approval", default: false
    t.integer "approval_count", default: 1
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_group_id"], name: "index_workflow_steps_on_assigned_to_group_id"
    t.index ["assigned_to_id"], name: "index_workflow_steps_on_assigned_to_id"
    t.index ["priority"], name: "index_workflow_steps_on_priority"
    t.index ["status"], name: "index_workflow_steps_on_status"
    t.index ["step_type"], name: "index_workflow_steps_on_step_type"
    t.index ["workflow_id", "position"], name: "index_workflow_steps_on_workflow_id_and_position", unique: true
    t.index ["workflow_id"], name: "index_workflow_steps_on_workflow_id"
  end

  create_table "workflow_submissions", force: :cascade do |t|
    t.bigint "workflow_id", null: false
    t.bigint "submitted_by_id", null: false
    t.bigint "current_step_id"
    t.string "status", default: "pending"
    t.jsonb "data", default: {}
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "completion_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_workflow_submissions_on_completed_at"
    t.index ["current_step_id"], name: "index_workflow_submissions_on_current_step_id"
    t.index ["started_at"], name: "index_workflow_submissions_on_started_at"
    t.index ["status"], name: "index_workflow_submissions_on_status"
    t.index ["submitted_by_id"], name: "index_workflow_submissions_on_submitted_by_id"
    t.index ["workflow_id"], name: "index_workflow_submissions_on_workflow_id"
  end

  create_table "workflows", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "organization_id", null: false
    t.string "workflow_type"
    t.jsonb "settings", default: {}
    t.string "status", default: "draft"
    t.boolean "is_template", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_template"], name: "index_workflows_on_is_template"
    t.index ["organization_id", "name"], name: "index_workflows_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_workflows_on_organization_id"
    t.index ["status"], name: "index_workflows_on_status"
    t.index ["workflow_type"], name: "index_workflows_on_workflow_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "authorizations", "user_groups"
  add_foreign_key "authorizations", "users"
  add_foreign_key "authorizations", "users", column: "granted_by_id"
  add_foreign_key "authorizations", "users", column: "revoked_by_id"
  add_foreign_key "basket_items", "baskets"
  add_foreign_key "baskets", "users"
  add_foreign_key "document_metadata", "documents"
  add_foreign_key "document_metadata", "metadata_templates"
  add_foreign_key "document_shares", "documents"
  add_foreign_key "document_shares", "users", column: "shared_by_id"
  add_foreign_key "document_shares", "users", column: "shared_with_id"
  add_foreign_key "document_tags", "documents"
  add_foreign_key "document_tags", "tags"
  add_foreign_key "document_validations", "documents"
  add_foreign_key "document_validations", "users", column: "validator_id"
  add_foreign_key "document_validations", "validation_requests"
  add_foreign_key "document_versions", "documents"
  add_foreign_key "document_versions", "users", column: "uploaded_by_id"
  add_foreign_key "documents", "documents", column: "parent_id"
  add_foreign_key "documents", "folders"
  add_foreign_key "documents", "spaces"
  add_foreign_key "documents", "users", column: "uploaded_by_id"
  add_foreign_key "folders", "folders", column: "parent_id"
  add_foreign_key "folders", "spaces"
  add_foreign_key "immo_promo_budget_lines", "immo_promo_budgets", column: "budget_id"
  add_foreign_key "immo_promo_budgets", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_budgets", "users", column: "approved_by_id"
  add_foreign_key "immo_promo_certifications", "immo_promo_stakeholders", column: "stakeholder_id"
  add_foreign_key "immo_promo_contracts", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_contracts", "immo_promo_stakeholders", column: "stakeholder_id"
  add_foreign_key "immo_promo_lot_specifications", "immo_promo_lots", column: "lot_id"
  add_foreign_key "immo_promo_lots", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_milestones", "immo_promo_phases", column: "phase_id"
  add_foreign_key "immo_promo_permit_conditions", "immo_promo_permits", column: "permit_id"
  add_foreign_key "immo_promo_permits", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_permits", "users", column: "approved_by_id"
  add_foreign_key "immo_promo_permits", "users", column: "submitted_by_id"
  add_foreign_key "immo_promo_phase_dependencies", "immo_promo_phases", column: "dependent_phase_id"
  add_foreign_key "immo_promo_phase_dependencies", "immo_promo_phases", column: "prerequisite_phase_id"
  add_foreign_key "immo_promo_phases", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_phases", "users", column: "responsible_user_id"
  add_foreign_key "immo_promo_progress_reports", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_progress_reports", "users", column: "prepared_by_id"
  add_foreign_key "immo_promo_projects", "organizations"
  add_foreign_key "immo_promo_projects", "users", column: "project_manager_id"
  add_foreign_key "immo_promo_reservations", "immo_promo_lots", column: "lot_id"
  add_foreign_key "immo_promo_risks", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_risks", "users", column: "owner_id"
  add_foreign_key "immo_promo_stakeholders", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_task_dependencies", "immo_promo_tasks", column: "dependent_task_id"
  add_foreign_key "immo_promo_task_dependencies", "immo_promo_tasks", column: "prerequisite_task_id"
  add_foreign_key "immo_promo_tasks", "immo_promo_phases", column: "phase_id"
  add_foreign_key "immo_promo_tasks", "immo_promo_stakeholders", column: "stakeholder_id"
  add_foreign_key "immo_promo_tasks", "users", column: "assigned_to_id"
  add_foreign_key "immo_promo_time_logs", "immo_promo_tasks", column: "task_id"
  add_foreign_key "immo_promo_time_logs", "users"
  add_foreign_key "metadata", "metadata_fields"
  add_foreign_key "metadata_fields", "metadata_templates"
  add_foreign_key "metadata_templates", "organizations"
  add_foreign_key "metadatum", "documents"
  add_foreign_key "notifications", "users"
  add_foreign_key "project_workflow_steps", "organizations"
  add_foreign_key "project_workflow_transitions", "organizations", column: "project_id"
  add_foreign_key "project_workflow_transitions", "project_workflow_steps", column: "from_step_id"
  add_foreign_key "project_workflow_transitions", "project_workflow_steps", column: "to_step_id"
  add_foreign_key "project_workflow_transitions", "users", column: "transitioned_by_id"
  add_foreign_key "search_queries", "users"
  add_foreign_key "shares", "user_groups", column: "shared_with_group_id"
  add_foreign_key "shares", "users", column: "shared_by_id"
  add_foreign_key "shares", "users", column: "shared_with_id"
  add_foreign_key "spaces", "organizations"
  add_foreign_key "tags", "organizations"
  add_foreign_key "user_features", "users"
  add_foreign_key "user_group_memberships", "user_groups"
  add_foreign_key "user_group_memberships", "users"
  add_foreign_key "user_groups", "organizations"
  add_foreign_key "users", "organizations"
  add_foreign_key "validation_requests", "documents"
  add_foreign_key "validation_requests", "users", column: "requester_id"
  add_foreign_key "validation_requests", "validation_templates"
  add_foreign_key "validation_templates", "organizations"
  add_foreign_key "workflow_steps", "user_groups", column: "assigned_to_group_id"
  add_foreign_key "workflow_steps", "users", column: "assigned_to_id"
  add_foreign_key "workflow_steps", "workflows"
  add_foreign_key "workflow_submissions", "users", column: "submitted_by_id"
  add_foreign_key "workflow_submissions", "workflow_steps", column: "current_step_id"
  add_foreign_key "workflow_submissions", "workflows"
  add_foreign_key "workflows", "organizations"
end
