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

ActiveRecord::Schema.define(version: 20160128144433) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
  end

  create_table "datasets", force: :cascade do |t|
    t.string   "key",                                           null: false
    t.string   "title"
    t.string   "creator_text"
    t.string   "identifier"
    t.string   "publisher"
    t.string   "publication_year"
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
    t.boolean  "has_datacite_change",         default: false
    t.string   "publication_state",           default: "draft"
    t.string   "version",                     default: "1"
    t.boolean  "curator_hold",                default: false
  end

  add_index "datasets", ["key"], name: "index_datasets_on_key", unique: true, using: :btree

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

  create_table "identities", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "licenses", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.string   "external_info_url"
    t.string   "full_text_url"
    t.string   "idb_help_url"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
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
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "email"
    t.string   "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
