json.extract!(
  theme,
  :id, :slug, :title, :group_id, :data, :parent_id, :status)

json.group_name theme.group.name
if theme.parent.present?
  json.parent_data theme.parent.data
end
json.merged_data theme.config_data
