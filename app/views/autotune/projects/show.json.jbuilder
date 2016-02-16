json.partial! 'autotune/projects/project', :project => @project

json.slug_sans_theme @project.slug_sans_theme

json.blueprint_config @project.blueprint_config
json.data @project.data

unless @project.meta['error_message'].blank?
  json.error_message @project.meta['error_message']
end

# render the embed html template and strip all linebreaks
json.embed_html render(
  :template => 'autotune/projects/_embed.html.erb').gsub(/\s*\n+\s*/, ' ')

# Only send build script output to superusers
json.output @project.output if role? :superuser
