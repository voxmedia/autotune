json.extract!(
  project,
  :status, :id, :blueprint_id, :slug, :title, :created_at, :updated_at,
  :preview_url, :publish_url, :user_id, :published_at, :data_updated_at,
  :blueprint_version, :blueprint_repo_url, :bespoke)

json.built project.built?
json.type project.type
if project.bespoke?
  json.blueprint_title 'Bespoke'
else
  json.blueprint_title project.blueprint.title
end
json.theme project.theme.slug
json.created_by project.user.name

if project.built? && (!project.live? || project.published?)
  if project.publishable? && !project.live?
    deployer = project.deployer(:preview)
  else
    deployer = project.deployer(:publish)
  end

  json.screenshot_sm_url deployer.url_for('screenshots/screenshot_s.png')
  json.screenshot_md_url deployer.url_for('screenshots/screenshot_m.png')
  json.screenshot_lg_url deployer.url_for('screenshots/screenshot_l.png')
  json.screenshot_smx2_url deployer.url_for('screenshots/screenshot_s@2.png')
  json.screenshot_mdx2_url deployer.url_for('screenshots/screenshot_m@2.png')
  json.screenshot_lgx2_url deployer.url_for('screenshots/screenshot_l@2.png')

  # render the embed html template and strip all linebreaks
  json.embed_html render(
    :template => 'autotune/projects/_embed.html.erb',
    :locals => { :project => project }).gsub(/\s*\n+\s*/, ' ')
end
