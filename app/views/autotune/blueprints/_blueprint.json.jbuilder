json.extract!(
  blueprint,
  :status, :mode, :id, :slug, :title, :type,
  :repo_url, :config, :created_at, :updated_at, :version)
json.thumb_url blueprint.thumb_url(current_user)

json.media_url blueprint.deployer(:media, :user => current_user).url_for('/')
