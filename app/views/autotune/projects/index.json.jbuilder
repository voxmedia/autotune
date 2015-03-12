json.array!(@projects) do |project|
  json.partial! 'autotune/projects/project', :project => project
end
