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

ActiveRecord::Schema.define(version: 20150210191559) do

  create_table "autotune_authorizations", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.text     "info"
    t.text     "credentials"
    t.text     "extra"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "autotune_authorizations", ["provider"], name: "index_autotune_authorizations_on_provider"
  add_index "autotune_authorizations", ["uid"], name: "index_autotune_authorizations_on_uid"
  add_index "autotune_authorizations", ["user_id"], name: "index_autotune_authorizations_on_user_id"

  create_table "autotune_blueprint_tags", force: :cascade do |t|
    t.integer  "blueprint_id"
    t.integer  "tag_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "autotune_blueprint_tags", ["blueprint_id"], name: "index_autotune_blueprint_tags_on_blueprint_id"
  add_index "autotune_blueprint_tags", ["tag_id"], name: "index_autotune_blueprint_tags_on_tag_id"

  create_table "autotune_blueprints", force: :cascade do |t|
    t.string   "slug"
    t.string   "type"
    t.string   "status"
    t.string   "title"
    t.string   "repo_url"
    t.string   "version"
    t.text     "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "autotune_blueprints", ["slug"], name: "index_autotune_blueprints_on_slug"
  add_index "autotune_blueprints", ["status"], name: "index_autotune_blueprints_on_status"
  add_index "autotune_blueprints", ["type"], name: "index_autotune_blueprints_on_type"

  create_table "autotune_projects", force: :cascade do |t|
    t.string   "slug"
    t.string   "theme"
    t.string   "status"
    t.string   "title"
    t.string   "blueprint_version"
    t.text     "data"
    t.text     "output"
    t.integer  "blueprint_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "autotune_projects", ["blueprint_id"], name: "index_autotune_projects_on_blueprint_id"
  add_index "autotune_projects", ["slug"], name: "index_autotune_projects_on_slug"
  add_index "autotune_projects", ["status"], name: "index_autotune_projects_on_status"
  add_index "autotune_projects", ["theme"], name: "index_autotune_projects_on_theme"

  create_table "autotune_tags", force: :cascade do |t|
    t.string   "slug"
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "autotune_tags", ["slug"], name: "index_autotune_tags_on_slug"

  create_table "autotune_users", force: :cascade do |t|
    t.string   "email"
    t.string   "name"
    t.string   "api_key"
    t.text     "meta"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "autotune_users", ["api_key"], name: "index_autotune_users_on_api_key"
  add_index "autotune_users", ["email"], name: "index_autotune_users_on_email"

end
