json.extract!(
  theme,
  :id, :slug, :title, :group_id, :data, :parent_id, :status)

json.group_name theme.group.name
json.parent_data theme.parent.data
json.merged_data theme.config_data
