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

ActiveRecord::Schema.define(version: 20161227165145) do

  create_table "autotune_authorizations", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.text     "info"
    t.text     "credentials"
    t.text     "extra",       limit: 131072
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
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
    t.string   "mode"
  end

  add_index "autotune_blueprints", ["slug"], name: "index_autotune_blueprints_on_slug"
  add_index "autotune_blueprints", ["status"], name: "index_autotune_blueprints_on_status"
  add_index "autotune_blueprints", ["type"], name: "index_autotune_blueprints_on_type"

  create_table "autotune_group_memberships", force: :cascade do |t|
    t.integer "user_id"
    t.integer "group_id"
    t.string  "role"
  end

  add_index "autotune_group_memberships", ["group_id"], name: "index_autotune_group_memberships_on_group_id"
  add_index "autotune_group_memberships", ["user_id"], name: "index_autotune_group_memberships_on_user_id"

  create_table "autotune_groups", force: :cascade do |t|
    t.string  "name"
    t.string  "slug"
    t.integer "external_id"
  end

  add_index "autotune_groups", ["name"], name: "index_autotune_groups_on_name"
  add_index "autotune_groups", ["slug"], name: "index_autotune_groups_on_slug"

  create_table "autotune_logs", force: :cascade do |t|
    t.string   "label"
    t.text     "content"
    t.integer  "time"
    t.integer  "project_id"
    t.integer  "blueprint_id"
    t.datetime "created_at"
    t.boolean  "success",      default: true
  end

  add_index "autotune_logs", ["blueprint_id"], name: "index_autotune_logs_on_blueprint_id"
  add_index "autotune_logs", ["created_at"], name: "index_autotune_logs_on_created_at"
  add_index "autotune_logs", ["label"], name: "index_autotune_logs_on_label"
  add_index "autotune_logs", ["project_id"], name: "index_autotune_logs_on_project_id"
  add_index "autotune_logs", ["time"], name: "index_autotune_logs_on_time"

  create_table "autotune_projects", force: :cascade do |t|
    t.string   "slug"
    t.string   "status"
    t.string   "title"
    t.string   "blueprint_version"
    t.text     "data",               limit: 131072
    t.text     "output"
    t.integer  "blueprint_id"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.integer  "user_id"
    t.text     "blueprint_config"
    t.datetime "published_at"
    t.datetime "data_updated_at"
    t.integer  "theme_id"
    t.text     "meta"
    t.integer  "group_id"
    t.boolean  "bespoke",                           default: false, null: false
    t.string   "blueprint_repo_url"
  end

  add_index "autotune_projects", ["blueprint_id"], name: "index_autotune_projects_on_blueprint_id"
  add_index "autotune_projects", ["slug"], name: "index_autotune_projects_on_slug"
  add_index "autotune_projects", ["status"], name: "index_autotune_projects_on_status"
  add_index "autotune_projects", ["theme_id"], name: "index_autotune_projects_on_theme_id"
  add_index "autotune_projects", ["user_id"], name: "index_autotune_projects_on_user_id"

  create_table "autotune_tags", force: :cascade do |t|
    t.string   "slug"
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "autotune_tags", ["slug"], name: "index_autotune_tags_on_slug"

  create_table "autotune_themes", force: :cascade do |t|
    t.string  "slug"
    t.string  "title"
    t.integer "group_id"
    t.string  "status"
    t.text    "data"
    t.integer "parent_id"
  end

  add_index "autotune_themes", ["parent_id"], name: "index_autotune_themes_on_parent_id"
  add_index "autotune_themes", ["status"], name: "index_autotune_themes_on_status"

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
