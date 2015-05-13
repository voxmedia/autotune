if role? :superuser
  json.extract!(
    project,
    :status, :id, :blueprint_id, :data, :output,
    :theme, :slug, :title, :created_at, :updated_at,
    :preview_url, :publish_url, :user_id, :published_at,
    :data_updated_at, :blueprint_version, :blueprint_config)
else
  json.extract!(
    project,
    :status, :id, :blueprint_id, :data,
    :theme, :slug, :title, :created_at, :updated_at,
    :preview_url, :publish_url, :user_id, :published_at,
    :data_updated_at, :blueprint_version, :blueprint_config)
end
