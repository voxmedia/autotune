json.array!(@projects) do |project|
  json.partial! 'projects/project', :project => project
end
