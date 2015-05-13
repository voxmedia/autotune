if role? :superuser
  json.extract!(
    project,
    :status, :id, :blueprint_id, :data, :output,
    :theme, :slug, :title, :created_at, :updated_at,
    :preview_url, :publish_url, :user_id, :published_at)
else
  json.extract!(
    project,
    :status, :id, :blueprint_id, :data,
    :theme, :slug, :title, :created_at, :updated_at,
    :preview_url, :publish_url, :user_id, :published_at)
end
