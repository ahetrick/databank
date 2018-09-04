# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180904182242) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin", force: :cascade do |t|
    t.text     "read_only_alert"
    t.integer  "singleton_guard"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "ar_internal_metadata", primary_key: "key", force: :cascade do |t|
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         default: 0
    t.string   "comment"
    t.string   "remote_address"
    t.string   "request_uuid"
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], name: "associated_index", using: :btree
  add_index "audits", ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
  add_index "audits", ["created_at"], name: "index_audits_on_created_at", using: :btree
  add_index "audits", ["request_uuid"], name: "index_audits_on_request_uuid", using: :btree
  add_index "audits", ["user_id", "user_type"], name: "user_index", using: :btree

  create_table "creators", force: :cascade do |t|
    t.integer  "dataset_id"
    t.string   "family_name"
    t.string   "given_name"
    t.string   "institution_name"
    t.string   "identifier"
    t.integer  "type_of"
    t.integer  "row_order"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "email"
    t.boolean  "is_contact",        default: false, null: false
    t.integer  "row_position"
    t.string   "identifier_scheme"
  end

  create_table "datafiles", force: :cascade do |t|
    t.string   "description"
    t.string   "binary"
    t.string   "web_id"
    t.integer  "dataset_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "job_id"
    t.string   "box_filename"
    t.string   "box_filesize_display"
    t.string   "medusa_id"
    t.string   "medusa_path"
    t.string   "binary_name"
    t.integer  "binary_size",          limit: 8
    t.integer  "upload_file_size",     limit: 8
    t.string   "upload_status"
    t.string   "peek_type"
    t.text     "peek_text"
    t.string   "storage_root"
    t.string   "storage_prefix"
    t.string   "storage_key"
    t.string   "mime_type"
  end

  create_table "dataset_download_tallies", force: :cascade do |t|
    t.string   "dataset_key"
    t.string   "doi"
    t.date     "download_date"
    t.integer  "tally"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "datasets", force: :cascade do |t|
    t.string   "key",                                           null: false
    t.string   "title"
    t.string   "creator_text"
    t.string   "identifier"
    t.string   "publisher"
    t.string   "description"
    t.string   "license"
    t.string   "depositor_name"
    t.string   "depositor_email"
    t.boolean  "complete"
    t.string   "corresponding_creator_name"
    t.string   "corresponding_creator_email"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.string   "keywords"
    t.string   "publication_state",           default: "draft"
    t.boolean  "curator_hold",                default: false
    t.date     "release_date"
    t.string   "embargo"
    t.boolean  "is_test",                     default: false
    t.boolean  "is_import",                   default: false
    t.date     "tombstone_date"
    t.string   "have_permission",             default: "no"
    t.string   "removed_private",             default: "no"
    t.string   "agree",                       default: "no"
    t.string   "hold_state",                  default: "none"
    t.string   "medusa_dataset_dir"
    t.string   "dataset_version",             default: "1"
    t.boolean  "suppress_changelog",          default: false
    t.text     "version_comment"
    t.string   "subject"
  end

  add_index "datasets", ["key"], name: "index_datasets_on_key", unique: true, using: :btree

  create_table "day_file_downloads", force: :cascade do |t|
    t.string   "ip_address"
    t.string   "file_web_id"
    t.string   "filename"
    t.string   "dataset_key"
    t.string   "doi"
    t.date     "download_date"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "deckfiles", force: :cascade do |t|
    t.string   "disposition", default: "ingest"
    t.boolean  "remove",      default: false
    t.string   "path"
    t.integer  "dataset_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "definitions", force: :cascade do |t|
    t.string   "term"
    t.string   "meaning"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",         default: 0, null: false
    t.integer  "attempts",         default: 0, null: false
    t.text     "handler",                      null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "progress_stage"
    t.integer  "progress_current", default: 0
    t.integer  "progress_max",     default: 0
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "featured_researchers", force: :cascade do |t|
    t.string   "name"
    t.string   "question"
    t.text     "bio"
    t.text     "testimonial"
    t.string   "binary"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "photo_url"
    t.string   "dataset_url"
    t.string   "article_url"
    t.boolean  "is_active"
  end

  create_table "file_download_tallies", force: :cascade do |t|
    t.string   "file_web_id"
    t.string   "filename"
    t.string   "dataset_key"
    t.string   "doi"
    t.date     "download_date"
    t.integer  "tally"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "funders", force: :cascade do |t|
    t.string   "name"
    t.string   "identifier"
    t.string   "identifier_scheme"
    t.string   "grant"
    t.integer  "dataset_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "code"
  end

  create_table "identities", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "medusa_ingests", force: :cascade do |t|
    t.string   "idb_class"
    t.string   "idb_identifier"
    t.string   "staging_path"
    t.string   "request_status"
    t.string   "medusa_path"
    t.string   "medusa_uuid"
    t.datetime "response_time"
    t.string   "error_text"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "medusa_dataset_dir"
    t.string   "draft_key"
    t.string   "medusa_key"
  end

  create_table "nested_items", force: :cascade do |t|
    t.integer  "datafile_id"
    t.integer  "parent_id"
    t.string   "item_name"
    t.string   "media_type"
    t.integer  "size",         limit: 8
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "item_path"
    t.boolean  "is_directory"
  end

  create_table "related_materials", force: :cascade do |t|
    t.string   "material_type"
    t.string   "availability"
    t.string   "link"
    t.string   "uri"
    t.string   "uri_type"
    t.text     "citation"
    t.integer  "dataset_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "selected_type"
    t.string   "datacite_list"
  end

  create_table "restoration_events", force: :cascade do |t|
    t.text     "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "restoration_id_maps", force: :cascade do |t|
    t.string   "id_class"
    t.integer  "old_id"
    t.integer  "new_id"
    t.integer  "restoration_event_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "robots", force: :cascade do |t|
    t.string   "source"
    t.string   "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "system_files", force: :cascade do |t|
    t.integer  "dataset_id"
    t.string   "storage_root"
    t.string   "storage_key"
    t.string   "file_type"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "tokens", force: :cascade do |t|
    t.string   "dataset_key"
    t.string   "identifier"
    t.datetime "expires"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "email"
    t.string   "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "username"
  end

end
