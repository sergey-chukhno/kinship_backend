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

ActiveRecord::Schema[7.1].define(version: 2025_10_17_074434) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

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

  create_table "api_accesses", force: :cascade do |t|
    t.string "token", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "availabilities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "monday", default: false
    t.boolean "tuesday", default: false
    t.boolean "wednesday", default: false
    t.boolean "thursday", default: false
    t.boolean "friday", default: false
    t.boolean "saturday", default: false
    t.boolean "sunday", default: false
    t.boolean "other", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_availabilities_on_user_id"
  end

  create_table "badge_skills", force: :cascade do |t|
    t.string "name", null: false
    t.integer "category", default: 0, null: false
    t.bigint "badge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_id"], name: "index_badge_skills_on_badge_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.integer "level", null: false
    t.string "series", default: "Série TouKouLeur", null: false
    t.index ["series"], name: "index_badges_on_series"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "zip_code", null: false
    t.string "city", null: false
    t.string "referent_phone_number", null: false
    t.string "description", null: false
    t.integer "status", default: 0, null: false
    t.bigint "company_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "siret_number"
    t.string "skill_additional_information"
    t.string "email"
    t.string "website"
    t.string "job"
    t.boolean "take_trainee", default: false
    t.boolean "propose_workshop", default: false
    t.boolean "propose_summer_job", default: false
    t.index ["company_type_id"], name: "index_companies_on_company_type_id"
  end

  create_table "company_api_accesses", force: :cascade do |t|
    t.bigint "api_access_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_access_id"], name: "index_company_api_accesses_on_api_access_id"
    t.index ["company_id"], name: "index_company_api_accesses_on_company_id"
  end

  create_table "company_companies", force: :cascade do |t|
    t.integer "status"
    t.bigint "company_sponsor_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_companies_on_company_id"
    t.index ["company_sponsor_id"], name: "index_company_companies_on_company_sponsor_id"
  end

  create_table "company_skills", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_skills_on_company_id"
    t.index ["skill_id"], name: "index_company_skills_on_skill_id"
  end

  create_table "company_sub_skills", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "sub_skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_sub_skills_on_company_id"
    t.index ["sub_skill_id"], name: "index_company_sub_skills_on_sub_skill_id"
  end

  create_table "company_types", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contracts", force: :cascade do |t|
    t.bigint "school_id"
    t.boolean "active", default: false, null: false
    t.datetime "start_date", null: false
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_contracts_on_company_id"
    t.index ["school_id"], name: "index_contracts_on_school_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id", null: false
    t.index ["project_id"], name: "index_keywords_on_project_id"
  end

  create_table "links", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_links_on_project_id"
  end

  create_table "loggings", force: :cascade do |t|
    t.string "ip_address", null: false
    t.string "request_path", null: false
    t.jsonb "request_path_params", default: {}, null: false
    t.integer "request_code", null: false
    t.datetime "request_time", null: false
    t.text "user_agent", null: false
    t.integer "user_id"
    t.string "user_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "partnership_members", force: :cascade do |t|
    t.bigint "partnership_id", null: false
    t.string "participant_type", null: false
    t.bigint "participant_id", null: false
    t.integer "member_status", default: 0, null: false
    t.integer "role_in_partnership", default: 0, null: false
    t.datetime "joined_at"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_status"], name: "index_partnership_members_on_member_status"
    t.index ["participant_type", "participant_id"], name: "idx_on_participant_type_participant_id_4f6c645201"
    t.index ["participant_type", "participant_id"], name: "index_partnership_members_on_participant"
    t.index ["partnership_id", "participant_id", "participant_type"], name: "index_partnership_members_unique", unique: true
    t.index ["partnership_id"], name: "index_partnership_members_on_partnership_id"
    t.index ["role_in_partnership"], name: "index_partnership_members_on_role_in_partnership"
  end

  create_table "partnerships", force: :cascade do |t|
    t.string "initiator_type", null: false
    t.bigint "initiator_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "partnership_type", default: 0, null: false
    t.boolean "share_members", default: false, null: false
    t.boolean "share_projects", default: true, null: false
    t.boolean "has_sponsorship", default: false, null: false
    t.string "name"
    t.text "description"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_at"], name: "index_partnerships_on_confirmed_at"
    t.index ["initiator_type", "initiator_id"], name: "index_partnerships_on_initiator"
    t.index ["initiator_type", "initiator_id"], name: "index_partnerships_on_initiator_type_and_initiator_id"
    t.index ["partnership_type"], name: "index_partnerships_on_partnership_type"
    t.index ["status"], name: "index_partnerships_on_status"
  end

  create_table "project_companies", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_project_companies_on_company_id"
    t.index ["project_id"], name: "index_project_companies_on_project_id"
  end

  create_table "project_members", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.index ["project_id"], name: "index_project_members_on_project_id"
    t.index ["role"], name: "index_project_members_on_role"
    t.index ["user_id"], name: "index_project_members_on_user_id"
  end

  create_table "project_school_levels", force: :cascade do |t|
    t.bigint "school_level_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_school_levels_on_project_id"
    t.index ["school_level_id"], name: "index_project_school_levels_on_school_level_id"
  end

  create_table "project_skills", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_skills_on_project_id"
    t.index ["skill_id"], name: "index_project_skills_on_skill_id"
  end

  create_table "project_tags", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_tags_on_project_id"
    t.index ["tag_id"], name: "index_project_tags_on_tag_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "start_date"
    t.datetime "end_date"
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "participants_number"
    t.integer "status"
    t.integer "time_spent"
    t.boolean "private", default: false
    t.bigint "partnership_id"
    t.index ["owner_id"], name: "index_projects_on_owner_id"
    t.index ["partnership_id"], name: "index_projects_on_partnership_id"
  end

  create_table "school_companies", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "company_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_school_companies_on_company_id"
    t.index ["school_id"], name: "index_school_companies_on_school_id"
  end

  create_table "school_levels", force: :cascade do |t|
    t.string "name"
    t.bigint "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "level"
    t.index ["school_id"], name: "index_school_levels_on_school_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name"
    t.string "zip_code"
    t.integer "school_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
    t.integer "status", default: 0, null: false
    t.string "referent_phone_number"
  end

  create_table "skills", force: :cascade do |t|
    t.string "name"
    t.boolean "official", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sub_skills", force: :cascade do |t|
    t.bigint "skill_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id"], name: "index_sub_skills_on_skill_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "team_members", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_members_on_team_id"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_teams_on_project_id"
  end

  create_table "user_badge_skills", force: :cascade do |t|
    t.bigint "user_badge_id", null: false
    t.bigint "badge_skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_skill_id"], name: "index_user_badge_skills_on_badge_skill_id"
    t.index ["user_badge_id"], name: "index_user_badge_skills_on_user_badge_id"
  end

  create_table "user_badges", force: :cascade do |t|
    t.string "project_title", null: false
    t.string "project_description", null: false
    t.integer "status", default: 0, null: false
    t.bigint "sender_id", null: false
    t.bigint "receiver_id", null: false
    t.bigint "badge_id", null: false
    t.bigint "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "organization_type", null: false
    t.bigint "organization_id", null: false
    t.text "comment"
    t.index ["badge_id"], name: "index_user_badges_on_badge_id"
    t.index ["organization_type", "organization_id"], name: "index_user_badges_on_organization"
    t.index ["project_id"], name: "index_user_badges_on_project_id"
    t.index ["receiver_id"], name: "index_user_badges_on_receiver_id"
    t.index ["sender_id"], name: "index_user_badges_on_sender_id"
  end

  create_table "user_companies", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "company_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.index ["company_id"], name: "index_user_companies_on_company_id"
    t.index ["role"], name: "index_user_companies_on_role"
    t.index ["user_id"], name: "index_user_companies_on_user_id"
  end

  create_table "user_school_levels", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "school_level_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_level_id"], name: "index_user_school_levels_on_school_level_id"
    t.index ["user_id"], name: "index_user_school_levels_on_user_id"
  end

  create_table "user_schools", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.index ["role"], name: "index_user_schools_on_role"
    t.index ["school_id"], name: "index_user_schools_on_school_id"
    t.index ["user_id"], name: "index_user_schools_on_user_id"
  end

  create_table "user_skills", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id"], name: "index_user_skills_on_skill_id"
    t.index ["user_id"], name: "index_user_skills_on_user_id"
  end

  create_table "user_sub_skills", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "sub_skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sub_skill_id"], name: "index_user_sub_skills_on_sub_skill_id"
    t.index ["user_id"], name: "index_user_sub_skills_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: ""
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "role"
    t.string "job"
    t.boolean "take_trainee", default: false
    t.boolean "admin", default: false
    t.boolean "is_banned", default: false
    t.date "birthday"
    t.bigint "parent_id"
    t.string "role_additional_information"
    t.string "skill_additional_information"
    t.string "contact_email", default: ""
    t.boolean "expend_skill_to_school", default: false
    t.boolean "accept_marketing", default: false
    t.boolean "accept_privacy_policy", default: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean "propose_workshop", default: false
    t.boolean "super_admin", default: false
    t.string "delete_token"
    t.datetime "delete_token_sent_at"
    t.boolean "certify", default: false
    t.boolean "show_my_skills", default: false, null: false
    t.string "badges_token"
    t.string "company_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["parent_id"], name: "index_users_on_parent_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "availabilities", "users"
  add_foreign_key "badge_skills", "badges"
  add_foreign_key "companies", "company_types"
  add_foreign_key "company_api_accesses", "api_accesses"
  add_foreign_key "company_api_accesses", "companies"
  add_foreign_key "company_companies", "companies"
  add_foreign_key "company_companies", "companies", column: "company_sponsor_id"
  add_foreign_key "company_skills", "companies"
  add_foreign_key "company_skills", "skills"
  add_foreign_key "company_sub_skills", "companies"
  add_foreign_key "company_sub_skills", "sub_skills"
  add_foreign_key "contracts", "companies"
  add_foreign_key "contracts", "schools"
  add_foreign_key "keywords", "projects"
  add_foreign_key "links", "projects"
  add_foreign_key "partnership_members", "partnerships"
  add_foreign_key "project_companies", "companies"
  add_foreign_key "project_companies", "projects"
  add_foreign_key "project_members", "projects"
  add_foreign_key "project_members", "users"
  add_foreign_key "project_school_levels", "projects"
  add_foreign_key "project_school_levels", "school_levels"
  add_foreign_key "project_skills", "projects"
  add_foreign_key "project_skills", "skills"
  add_foreign_key "project_tags", "projects"
  add_foreign_key "project_tags", "tags"
  add_foreign_key "projects", "partnerships"
  add_foreign_key "projects", "users", column: "owner_id"
  add_foreign_key "school_companies", "companies"
  add_foreign_key "school_companies", "schools"
  add_foreign_key "school_levels", "schools"
  add_foreign_key "sub_skills", "skills"
  add_foreign_key "team_members", "teams"
  add_foreign_key "team_members", "users"
  add_foreign_key "teams", "projects"
  add_foreign_key "user_badge_skills", "badge_skills"
  add_foreign_key "user_badge_skills", "user_badges"
  add_foreign_key "user_badges", "badges"
  add_foreign_key "user_badges", "projects"
  add_foreign_key "user_badges", "users", column: "receiver_id"
  add_foreign_key "user_badges", "users", column: "sender_id"
  add_foreign_key "user_companies", "companies"
  add_foreign_key "user_companies", "users"
  add_foreign_key "user_school_levels", "school_levels"
  add_foreign_key "user_school_levels", "users"
  add_foreign_key "user_schools", "schools"
  add_foreign_key "user_schools", "users"
  add_foreign_key "user_skills", "skills"
  add_foreign_key "user_skills", "users"
  add_foreign_key "user_sub_skills", "sub_skills"
  add_foreign_key "user_sub_skills", "users"
  add_foreign_key "users", "users", column: "parent_id"
end
