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

ActiveRecord::Schema[7.1].define(version: 2025_06_07_190455) do
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
    t.bigint "user_id", null: false
    t.bigint "user_group_id", null: false
    t.string "permission_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authorizable_type", "authorizable_id"], name: "index_authorizations_on_authorizable"
    t.index ["user_group_id"], name: "index_authorizations_on_user_group_id"
    t.index ["user_id"], name: "index_authorizations_on_user_id"
  end

  create_table "basket_items", force: :cascade do |t|
    t.bigint "basket_id", null: false
    t.bigint "document_id", null: false
    t.integer "position"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["basket_id", "document_id"], name: "index_basket_items_on_basket_id_and_document_id", unique: true
    t.index ["basket_id"], name: "index_basket_items_on_basket_id"
    t.index ["document_id"], name: "index_basket_items_on_document_id"
  end

  create_table "baskets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "is_shared", default: false
    t.string "share_token"
    t.datetime "share_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["share_token"], name: "index_baskets_on_share_token", unique: true
    t.index ["user_id"], name: "index_baskets_on_user_id"
  end

  create_table "document_metadata", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "metadata_field_id", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "metadata_field_id"], name: "idx_doc_metadata_unique", unique: true
    t.index ["document_id"], name: "index_document_metadata_on_document_id"
    t.index ["metadata_field_id"], name: "index_document_metadata_on_metadata_field_id"
  end

  create_table "document_shares", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "user_id", null: false
    t.string "permission"
    t.datetime "expires_at"
    t.bigint "shared_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_document_shares_on_document_id"
    t.index ["shared_by_id"], name: "index_document_shares_on_shared_by_id"
    t.index ["user_id"], name: "index_document_shares_on_user_id"
  end

  create_table "document_tags", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_document_tags_on_document_id"
    t.index ["tag_id"], name: "index_document_tags_on_tag_id"
  end

  create_table "document_versions", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.integer "version_number"
    t.text "comment"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_document_versions_on_created_by_id"
    t.index ["document_id"], name: "index_document_versions_on_document_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "content"
    t.text "extracted_content"
    t.string "status"
    t.bigint "user_id", null: false
    t.bigint "space_id", null: false
    t.bigint "folder_id"
    t.date "retention_date"
    t.date "destruction_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_id"
    t.index ["folder_id"], name: "index_documents_on_folder_id"
    t.index ["parent_id"], name: "index_documents_on_parent_id"
    t.index ["space_id"], name: "index_documents_on_space_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "folders", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "space_id", null: false
    t.string "ancestry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_id"
    t.string "slug"
    t.index ["ancestry"], name: "index_folders_on_ancestry"
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["space_id", "slug"], name: "index_folders_on_space_id_and_slug", unique: true
    t.index ["space_id"], name: "index_folders_on_space_id"
  end

  create_table "immo_promo_budget_lines", force: :cascade do |t|
    t.bigint "budget_id", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.text "description"
    t.integer "amount_cents", null: false
    t.integer "spent_amount_cents"
    t.string "currency", default: "EUR"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id"], name: "index_immo_promo_budget_lines_on_budget_id"
  end

  create_table "immo_promo_budgets", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.string "budget_type", null: false
    t.integer "version", null: false
    t.boolean "is_current", default: false
    t.integer "total_amount_cents", null: false
    t.integer "spent_amount_cents"
    t.string "currency", default: "EUR"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_current"], name: "index_immo_promo_budgets_on_is_current"
    t.index ["project_id", "version"], name: "index_immo_promo_budgets_on_project_id_and_version", unique: true
    t.index ["project_id"], name: "index_immo_promo_budgets_on_project_id"
  end

  create_table "immo_promo_certifications", force: :cascade do |t|
    t.bigint "stakeholder_id", null: false
    t.string "certification_type", null: false
    t.string "name", null: false
    t.string "certificate_number", null: false
    t.string "issuing_authority", null: false
    t.text "description"
    t.datetime "issue_date"
    t.datetime "expiry_date"
    t.boolean "is_valid", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certification_type"], name: "index_immo_promo_certifications_on_certification_type"
    t.index ["is_valid"], name: "index_immo_promo_certifications_on_is_valid"
    t.index ["stakeholder_id", "certificate_number"], name: "idx_on_stakeholder_id_certificate_number_0a56283856", unique: true
    t.index ["stakeholder_id"], name: "index_immo_promo_certifications_on_stakeholder_id"
  end

  create_table "immo_promo_contracts", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "stakeholder_id", null: false
    t.string "reference", null: false
    t.string "contract_type", null: false
    t.string "status", default: "draft"
    t.text "description"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "signature_date"
    t.integer "amount_cents", null: false
    t.integer "paid_amount_cents"
    t.string "currency", default: "EUR"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_type"], name: "index_immo_promo_contracts_on_contract_type"
    t.index ["project_id", "reference"], name: "index_immo_promo_contracts_on_project_id_and_reference", unique: true
    t.index ["project_id"], name: "index_immo_promo_contracts_on_project_id"
    t.index ["stakeholder_id"], name: "index_immo_promo_contracts_on_stakeholder_id"
    t.index ["status"], name: "index_immo_promo_contracts_on_status"
  end

  create_table "immo_promo_lot_specifications", force: :cascade do |t|
    t.bigint "lot_id", null: false
    t.string "specification_type", null: false
    t.string "name", null: false
    t.text "description"
    t.string "value"
    t.boolean "is_standard", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_standard"], name: "index_immo_promo_lot_specifications_on_is_standard"
    t.index ["lot_id"], name: "index_immo_promo_lot_specifications_on_lot_id"
    t.index ["specification_type"], name: "index_immo_promo_lot_specifications_on_specification_type"
  end

  create_table "immo_promo_lots", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "reference", null: false
    t.string "lot_type", null: false
    t.string "status", default: "planned"
    t.decimal "surface_area", precision: 10, scale: 2, null: false
    t.decimal "balcony_area", precision: 10, scale: 2
    t.integer "floor_level", null: false
    t.integer "rooms_count"
    t.integer "base_price_cents"
    t.integer "final_price_cents"
    t.string "currency", default: "EUR"
    t.text "description"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lot_type"], name: "index_immo_promo_lots_on_lot_type"
    t.index ["project_id", "reference"], name: "index_immo_promo_lots_on_project_id_and_reference", unique: true
    t.index ["project_id"], name: "index_immo_promo_lots_on_project_id"
    t.index ["status"], name: "index_immo_promo_lots_on_status"
  end

  create_table "immo_promo_milestones", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "phase_id"
    t.string "name", null: false
    t.text "description"
    t.string "milestone_type", null: false
    t.string "status", default: "pending"
    t.boolean "is_critical", default: false
    t.datetime "target_date"
    t.datetime "actual_date"
    t.datetime "completed_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_id"], name: "index_immo_promo_milestones_on_phase_id"
    t.index ["project_id"], name: "index_immo_promo_milestones_on_project_id"
  end

  create_table "immo_promo_permit_conditions", force: :cascade do |t|
    t.bigint "permit_id", null: false
    t.string "condition_type", null: false
    t.text "description", null: false
    t.boolean "is_fulfilled", default: false
    t.datetime "due_date"
    t.datetime "fulfilled_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_type"], name: "index_immo_promo_permit_conditions_on_condition_type"
    t.index ["is_fulfilled"], name: "index_immo_promo_permit_conditions_on_is_fulfilled"
    t.index ["permit_id"], name: "index_immo_promo_permit_conditions_on_permit_id"
  end

  create_table "immo_promo_permits", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "permit_type", null: false
    t.string "status", default: "draft"
    t.string "reference_number", null: false
    t.string "authority", null: false
    t.text "description"
    t.datetime "submission_date"
    t.datetime "expected_decision_date"
    t.datetime "actual_decision_date"
    t.datetime "expiry_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permit_type"], name: "index_immo_promo_permits_on_permit_type"
    t.index ["project_id", "reference_number"], name: "index_immo_promo_permits_on_project_id_and_reference_number", unique: true
    t.index ["project_id"], name: "index_immo_promo_permits_on_project_id"
    t.index ["status"], name: "index_immo_promo_permits_on_status"
  end

  create_table "immo_promo_phase_dependencies", force: :cascade do |t|
    t.bigint "prerequisite_phase_id", null: false
    t.bigint "dependent_phase_id", null: false
    t.string "dependency_type", default: "finish_to_start"
    t.integer "lag_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dependent_phase_id"], name: "index_immo_promo_phase_dependencies_on_dependent_phase_id"
    t.index ["prerequisite_phase_id", "dependent_phase_id"], name: "index_phase_dependencies_unique", unique: true
    t.index ["prerequisite_phase_id"], name: "index_immo_promo_phase_dependencies_on_prerequisite_phase_id"
  end

  create_table "immo_promo_phases", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "responsible_user_id"
    t.string "name", null: false
    t.text "description"
    t.string "phase_type", null: false
    t.string "status", default: "pending"
    t.integer "position", null: false
    t.boolean "is_critical", default: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "actual_start_date"
    t.datetime "actual_end_date"
    t.integer "budget_cents"
    t.integer "actual_cost_cents"
    t.string "currency", default: "EUR"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_type"], name: "index_immo_promo_phases_on_phase_type"
    t.index ["project_id", "position"], name: "index_immo_promo_phases_on_project_id_and_position", unique: true
    t.index ["project_id"], name: "index_immo_promo_phases_on_project_id"
    t.index ["responsible_user_id"], name: "index_immo_promo_phases_on_responsible_user_id"
    t.index ["status"], name: "index_immo_promo_phases_on_status"
  end

  create_table "immo_promo_progress_reports", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "created_by_id", null: false
    t.string "report_type", null: false
    t.date "report_date", null: false
    t.decimal "overall_progress_percentage", precision: 5, scale: 2
    t.text "accomplishments"
    t.text "issues"
    t.text "delays"
    t.text "next_steps"
    t.text "weather_conditions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_immo_promo_progress_reports_on_created_by_id"
    t.index ["project_id"], name: "index_immo_promo_progress_reports_on_project_id"
    t.index ["report_date"], name: "index_immo_promo_progress_reports_on_report_date"
    t.index ["report_type"], name: "index_immo_promo_progress_reports_on_report_type"
  end

  create_table "immo_promo_projects", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "project_manager_id"
    t.string "name", null: false
    t.string "reference", null: false
    t.text "description"
    t.string "project_type", null: false
    t.string "status", default: "planning"
    t.string "address"
    t.string "city"
    t.string "postal_code"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "actual_start_date"
    t.datetime "actual_end_date"
    t.integer "total_budget_cents"
    t.integer "current_budget_cents"
    t.string "currency", default: "EUR"
    t.integer "total_units"
    t.decimal "total_surface_area", precision: 10, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "reference"], name: "index_immo_promo_projects_on_organization_id_and_reference", unique: true
    t.index ["organization_id"], name: "index_immo_promo_projects_on_organization_id"
    t.index ["project_manager_id"], name: "index_immo_promo_projects_on_project_manager_id"
    t.index ["project_type"], name: "index_immo_promo_projects_on_project_type"
    t.index ["status"], name: "index_immo_promo_projects_on_status"
  end

  create_table "immo_promo_reservations", force: :cascade do |t|
    t.bigint "lot_id", null: false
    t.bigint "client_id", null: false
    t.string "status", default: "pending"
    t.datetime "reservation_date", null: false
    t.datetime "expiry_date", null: false
    t.datetime "confirmation_date"
    t.integer "deposit_amount_cents"
    t.integer "final_price_cents", null: false
    t.string "currency", default: "EUR"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_immo_promo_reservations_on_client_id"
    t.index ["lot_id"], name: "index_immo_promo_reservations_on_lot_id"
    t.index ["reservation_date"], name: "index_immo_promo_reservations_on_reservation_date"
    t.index ["status"], name: "index_immo_promo_reservations_on_status"
  end

  create_table "immo_promo_risks", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "identified_by_id", null: false
    t.bigint "assigned_to_id"
    t.string "title", null: false
    t.text "description"
    t.string "risk_type", null: false
    t.string "probability", null: false
    t.string "impact", null: false
    t.string "status", default: "identified"
    t.text "mitigation_plan"
    t.text "contingency_plan"
    t.datetime "identified_at"
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_immo_promo_risks_on_assigned_to_id"
    t.index ["identified_by_id"], name: "index_immo_promo_risks_on_identified_by_id"
    t.index ["probability", "impact"], name: "index_immo_promo_risks_on_probability_and_impact"
    t.index ["project_id"], name: "index_immo_promo_risks_on_project_id"
    t.index ["risk_type"], name: "index_immo_promo_risks_on_risk_type"
    t.index ["status"], name: "index_immo_promo_risks_on_status"
  end

  create_table "immo_promo_stakeholders", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.string "stakeholder_type", null: false
    t.string "email"
    t.string "phone", null: false
    t.string "contact_person"
    t.string "siret"
    t.boolean "is_active", default: true
    t.string "address"
    t.string "city"
    t.string "postal_code"
    t.string "country"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_immo_promo_stakeholders_on_is_active"
    t.index ["project_id"], name: "index_immo_promo_stakeholders_on_project_id"
    t.index ["stakeholder_type"], name: "index_immo_promo_stakeholders_on_stakeholder_type"
  end

  create_table "immo_promo_task_dependencies", force: :cascade do |t|
    t.bigint "prerequisite_task_id", null: false
    t.bigint "dependent_task_id", null: false
    t.string "dependency_type", default: "finish_to_start"
    t.integer "lag_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dependent_task_id"], name: "index_immo_promo_task_dependencies_on_dependent_task_id"
    t.index ["prerequisite_task_id", "dependent_task_id"], name: "index_task_dependencies_unique", unique: true
    t.index ["prerequisite_task_id"], name: "index_immo_promo_task_dependencies_on_prerequisite_task_id"
  end

  create_table "immo_promo_tasks", force: :cascade do |t|
    t.bigint "phase_id", null: false
    t.bigint "assigned_to_id"
    t.bigint "stakeholder_id"
    t.string "name", null: false
    t.text "description"
    t.string "task_type", null: false
    t.string "status", default: "pending"
    t.string "priority", default: "medium"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "actual_start_date"
    t.datetime "actual_end_date"
    t.decimal "estimated_hours", precision: 8, scale: 2
    t.integer "estimated_cost_cents"
    t.integer "actual_cost_cents"
    t.string "currency", default: "EUR"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_immo_promo_tasks_on_assigned_to_id"
    t.index ["phase_id"], name: "index_immo_promo_tasks_on_phase_id"
    t.index ["priority"], name: "index_immo_promo_tasks_on_priority"
    t.index ["stakeholder_id"], name: "index_immo_promo_tasks_on_stakeholder_id"
    t.index ["status"], name: "index_immo_promo_tasks_on_status"
    t.index ["task_type"], name: "index_immo_promo_tasks_on_task_type"
  end

  create_table "immo_promo_time_logs", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "user_id", null: false
    t.decimal "hours", precision: 8, scale: 2, null: false
    t.date "log_date", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["log_date"], name: "index_immo_promo_time_logs_on_log_date"
    t.index ["task_id", "user_id", "log_date"], name: "index_immo_promo_time_logs_on_task_id_and_user_id_and_log_date", unique: true
    t.index ["task_id"], name: "index_immo_promo_time_logs_on_task_id"
    t.index ["user_id"], name: "index_immo_promo_time_logs_on_user_id"
  end

  create_table "links", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "linked_document_id", null: false
    t.string "link_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_links_on_document_id"
    t.index ["linked_document_id"], name: "index_links_on_linked_document_id"
  end

  create_table "metadata", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.string "key"
    t.text "value"
    t.string "metadata_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_metadata_on_document_id"
  end

  create_table "metadata_fields", force: :cascade do |t|
    t.string "name", null: false
    t.string "field_type", null: false
    t.boolean "is_required", default: false
    t.json "options"
    t.bigint "metadata_template_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata_template_id"], name: "index_metadata_fields_on_metadata_template_id"
  end

  create_table "metadata_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_metadata_templates_on_organization_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notification_type", null: false
    t.string "title"
    t.text "message"
    t.boolean "is_read", default: false
    t.json "data"
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_read"], name: "index_notifications_on_is_read"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "project_workflow_steps", force: :cascade do |t|
    t.string "workflowable_type", null: false
    t.bigint "workflowable_id", null: false
    t.string "name"
    t.text "description"
    t.integer "position"
    t.string "status"
    t.bigint "assigned_to_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_project_workflow_steps_on_assigned_to_id"
    t.index ["workflowable_type", "workflowable_id"], name: "index_project_workflow_steps_on_workflowable"
  end

  create_table "project_workflow_transitions", force: :cascade do |t|
    t.string "workflowable_type", null: false
    t.bigint "workflowable_id", null: false
    t.string "from_status"
    t.string "to_status"
    t.bigint "user_id", null: false
    t.text "comment"
    t.datetime "transitioned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_project_workflow_transitions_on_user_id"
    t.index ["workflowable_type", "workflowable_id"], name: "index_project_workflow_transitions_on_workflowable"
  end

  create_table "search_queries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "query", null: false
    t.string "search_type"
    t.json "filters"
    t.integer "results_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["query"], name: "index_search_queries_on_query"
    t.index ["search_type"], name: "index_search_queries_on_search_type"
    t.index ["user_id"], name: "index_search_queries_on_user_id"
  end

  create_table "shares", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "user_id", null: false
    t.string "permission"
    t.datetime "expires_at"
    t.bigint "shared_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_shares_on_document_id"
    t.index ["shared_by_id"], name: "index_shares_on_shared_by_id"
    t.index ["user_id"], name: "index_shares_on_user_id"
  end

  create_table "spaces", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_spaces_on_organization_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "user_group_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "user_group_id", null: false
    t.string "role"
    t.text "permissions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_group_id"], name: "index_user_group_memberships_on_user_group_id"
    t.index ["user_id"], name: "index_user_group_memberships_on_user_id"
  end

  create_table "user_groups", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "group_type"
    t.boolean "is_active", default: true
    t.index ["group_type"], name: "index_user_groups_on_group_type"
    t.index ["is_active"], name: "index_user_groups_on_is_active"
    t.index ["organization_id"], name: "index_user_groups_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.text "permissions"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "workflow_steps", force: :cascade do |t|
    t.bigint "workflow_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "step_type"
    t.integer "position"
    t.json "conditions"
    t.json "actions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending"
    t.bigint "assignee_id"
    t.bigint "completed_by_id"
    t.datetime "completed_at"
    t.index ["assignee_id"], name: "index_workflow_steps_on_assignee_id"
    t.index ["completed_by_id"], name: "index_workflow_steps_on_completed_by_id"
    t.index ["position"], name: "index_workflow_steps_on_position"
    t.index ["status"], name: "index_workflow_steps_on_status"
    t.index ["workflow_id"], name: "index_workflow_steps_on_workflow_id"
  end

  create_table "workflow_submissions", force: :cascade do |t|
    t.bigint "workflow_id", null: false
    t.string "submittable_type", null: false
    t.bigint "submittable_id", null: false
    t.bigint "submitted_by_id", null: false
    t.bigint "current_step_id"
    t.string "status", default: "pending"
    t.integer "position"
    t.string "priority", default: "normal"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "due_date"
    t.string "decision"
    t.text "decision_comment"
    t.bigint "decided_by_id"
    t.datetime "decided_at"
    t.json "metadata"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_step_id"], name: "index_workflow_submissions_on_current_step_id"
    t.index ["decided_by_id"], name: "index_workflow_submissions_on_decided_by_id"
    t.index ["due_date"], name: "index_workflow_submissions_on_due_date"
    t.index ["priority"], name: "index_workflow_submissions_on_priority"
    t.index ["status"], name: "index_workflow_submissions_on_status"
    t.index ["submittable_type", "submittable_id"], name: "index_workflow_submissions_on_submittable"
    t.index ["submitted_by_id"], name: "index_workflow_submissions_on_submitted_by_id"
    t.index ["workflow_id", "position"], name: "index_workflow_submissions_on_workflow_id_and_position"
    t.index ["workflow_id", "submittable_type", "submittable_id"], name: "index_workflow_submissions_on_workflow_and_submittable", unique: true
    t.index ["workflow_id"], name: "index_workflow_submissions_on_workflow_id"
  end

  create_table "workflows", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "workflow_type"
    t.boolean "is_active", default: true
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.json "configuration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "draft"
    t.index ["is_active"], name: "index_workflows_on_is_active"
    t.index ["organization_id"], name: "index_workflows_on_organization_id"
    t.index ["status"], name: "index_workflows_on_status"
    t.index ["user_id"], name: "index_workflows_on_user_id"
    t.index ["workflow_type"], name: "index_workflows_on_workflow_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "authorizations", "user_groups"
  add_foreign_key "authorizations", "users"
  add_foreign_key "basket_items", "baskets"
  add_foreign_key "basket_items", "documents"
  add_foreign_key "baskets", "users"
  add_foreign_key "document_metadata", "documents"
  add_foreign_key "document_metadata", "metadata_fields"
  add_foreign_key "document_shares", "documents"
  add_foreign_key "document_shares", "users"
  add_foreign_key "document_shares", "users", column: "shared_by_id"
  add_foreign_key "document_tags", "documents"
  add_foreign_key "document_tags", "tags"
  add_foreign_key "document_versions", "documents"
  add_foreign_key "document_versions", "users", column: "created_by_id"
  add_foreign_key "documents", "documents", column: "parent_id"
  add_foreign_key "documents", "folders"
  add_foreign_key "documents", "spaces"
  add_foreign_key "documents", "users"
  add_foreign_key "folders", "folders", column: "parent_id"
  add_foreign_key "folders", "spaces"
  add_foreign_key "immo_promo_budget_lines", "immo_promo_budgets", column: "budget_id"
  add_foreign_key "immo_promo_budgets", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_certifications", "immo_promo_stakeholders", column: "stakeholder_id"
  add_foreign_key "immo_promo_contracts", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_contracts", "immo_promo_stakeholders", column: "stakeholder_id"
  add_foreign_key "immo_promo_lot_specifications", "immo_promo_lots", column: "lot_id"
  add_foreign_key "immo_promo_lots", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_milestones", "immo_promo_phases", column: "phase_id"
  add_foreign_key "immo_promo_milestones", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_permit_conditions", "immo_promo_permits", column: "permit_id"
  add_foreign_key "immo_promo_permits", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_phase_dependencies", "immo_promo_phases", column: "dependent_phase_id"
  add_foreign_key "immo_promo_phase_dependencies", "immo_promo_phases", column: "prerequisite_phase_id"
  add_foreign_key "immo_promo_phases", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_phases", "users", column: "responsible_user_id"
  add_foreign_key "immo_promo_progress_reports", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_progress_reports", "users", column: "created_by_id"
  add_foreign_key "immo_promo_projects", "organizations"
  add_foreign_key "immo_promo_projects", "users", column: "project_manager_id"
  add_foreign_key "immo_promo_reservations", "immo_promo_lots", column: "lot_id"
  add_foreign_key "immo_promo_reservations", "users", column: "client_id"
  add_foreign_key "immo_promo_risks", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_risks", "users", column: "assigned_to_id"
  add_foreign_key "immo_promo_risks", "users", column: "identified_by_id"
  add_foreign_key "immo_promo_stakeholders", "immo_promo_projects", column: "project_id"
  add_foreign_key "immo_promo_task_dependencies", "immo_promo_tasks", column: "dependent_task_id"
  add_foreign_key "immo_promo_task_dependencies", "immo_promo_tasks", column: "prerequisite_task_id"
  add_foreign_key "immo_promo_tasks", "immo_promo_phases", column: "phase_id"
  add_foreign_key "immo_promo_tasks", "immo_promo_stakeholders", column: "stakeholder_id"
  add_foreign_key "immo_promo_tasks", "users", column: "assigned_to_id"
  add_foreign_key "immo_promo_time_logs", "immo_promo_tasks", column: "task_id"
  add_foreign_key "immo_promo_time_logs", "users"
  add_foreign_key "links", "documents"
  add_foreign_key "links", "documents", column: "linked_document_id"
  add_foreign_key "metadata", "documents"
  add_foreign_key "metadata_fields", "metadata_templates"
  add_foreign_key "metadata_templates", "organizations"
  add_foreign_key "notifications", "users"
  add_foreign_key "project_workflow_steps", "users", column: "assigned_to_id"
  add_foreign_key "project_workflow_transitions", "users"
  add_foreign_key "search_queries", "users"
  add_foreign_key "shares", "documents"
  add_foreign_key "shares", "users"
  add_foreign_key "shares", "users", column: "shared_by_id"
  add_foreign_key "spaces", "organizations"
  add_foreign_key "user_group_memberships", "user_groups"
  add_foreign_key "user_group_memberships", "users"
  add_foreign_key "user_groups", "organizations"
  add_foreign_key "users", "organizations"
  add_foreign_key "workflow_steps", "users", column: "assignee_id"
  add_foreign_key "workflow_steps", "users", column: "completed_by_id"
  add_foreign_key "workflow_steps", "workflows"
  add_foreign_key "workflow_submissions", "users", column: "decided_by_id"
  add_foreign_key "workflow_submissions", "users", column: "submitted_by_id"
  add_foreign_key "workflow_submissions", "workflow_steps", column: "current_step_id"
  add_foreign_key "workflow_submissions", "workflows"
  add_foreign_key "workflows", "organizations"
  add_foreign_key "workflows", "users"
end
