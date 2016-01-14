json.extract!(
  blueprint,
  :status, :id, :slug, :title, :type,
  :repo_url, :config, :created_at, :updated_at,
  :thumb_url, :version)
json.media_url blueprint.deployer(:media).url_for('/')
