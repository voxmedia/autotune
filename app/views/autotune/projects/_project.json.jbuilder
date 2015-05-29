if role? :superuser
  json.extract!(
    project,
    :status, :id, :blueprint_id, :blueprint_title, 
    :data, :output,:theme, :slug, :title, :created_at,
    :created_by, :updated_at, :preview_url, :publish_url, 
    :user_id, :published_at, :data_updated_at, 
    :blueprint_version, :blueprint_config)
else
  json.extract!(
    project,
    :status, :id, :blueprint_id, :blueprint_title,
    :data, :theme, :slug, :title, :created_at,
    :created_by, :updated_at, :preview_url,
    :publish_url, :user_id, :published_at, :data_updated_at,
    :blueprint_version, :blueprint_config)
end
