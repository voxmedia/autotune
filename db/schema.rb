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

ActiveRecord::Schema.define(version: 20150209220424) do

  create_table "blueprint_tags", force: :cascade do |t|
    t.integer  "blueprint_id"
    t.integer  "tag_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "blueprint_tags", ["blueprint_id"], name: "index_blueprint_tags_on_blueprint_id"
  add_index "blueprint_tags", ["tag_id"], name: "index_blueprint_tags_on_tag_id"

  create_table "blueprints", force: :cascade do |t|
    t.string   "title"
    t.string   "status"
    t.string   "repo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "blueprints"
    t.string   "slug"
  end

  create_table "builds", force: :cascade do |t|
    t.string   "title"
    t.string   "slug"
    t.text     "data"
    t.string   "status"
    t.text     "output"
    t.integer  "blueprint_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "builds", ["blueprint_id"], name: "index_builds_on_blueprint_id"

  create_table "tags", force: :cascade do |t|
    t.string   "title"
    t.string   "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
