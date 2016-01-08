json.extract!(
  theme,
  :id, :slug, :title, :group_id, :data, :parent_id)

json.group_name theme.group.name
