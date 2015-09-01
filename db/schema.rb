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

ActiveRecord::Schema.define(version: 20150901210024) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "binaries", force: :cascade do |t|
    t.string   "datafile"
    t.integer  "dataset_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "description"
  end

  create_table "creators", force: :cascade do |t|
    t.string   "creator_name"
    t.string   "identifier"
    t.integer  "dataset_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "datasets", force: :cascade do |t|
    t.string   "title"
    t.string   "identifier"
    t.string   "publisher"
    t.string   "publication_year"
    t.string   "creator_ordered_ids"
    t.string   "license"
    t.string   "key"
    t.string   "description"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "creator_text"
    t.string   "depositor_name"
    t.string   "depositor_email"
    t.boolean  "complete",            default: false
  end

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
    t.string   "email"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "role"
  end

end
