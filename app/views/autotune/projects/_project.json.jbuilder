json.extract!(
  project,
  :status, :id, :blueprint_id, :slug, :title, :created_at, :updated_at,
  :preview_url, :publish_url, :user_id, :published_at, :data_updated_at,
  :blueprint_version)

json.built project.built?
json.type project.blueprint.type
json.blueprint_title project.blueprint.title
json.theme project.theme.slug
json.created_by project.user.name

if project.built?
  if project.publishable?
    deployer = project.deployer(:preview)
  else
    deployer = project.deployer(:publish)
  end

  json.screenshot_sm_url deployer.url_for('screenshots/screenshot_s.png')
  json.screenshot_md_url deployer.url_for('screenshots/screenshot_m.png')
  json.screenshot_lg_url deployer.url_for('screenshots/screenshot_l.png')
end
