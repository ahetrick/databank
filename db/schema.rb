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

ActiveRecord::Schema.define(version: 20151007180002) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "binaries", force: :cascade do |t|
    t.string   "attachment"
    t.string   "description"
    t.integer  "dataset_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "datafiles", force: :cascade do |t|
    t.string   "description"
    t.string   "repo_url"
    t.integer  "dataset_id"
    t.string   "dataset_key"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "web_id"
    t.string   "attachment"
  end

  create_table "datasets", force: :cascade do |t|
    t.string   "key",                         null: false
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
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "keywords"
  end

  add_index "datasets", ["key"], name: "index_datasets_on_key", unique: true, using: :btree

  create_table "identities", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
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
