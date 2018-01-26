json.array!(@themes) do |theme|
  json.partial! 'autotune/themes/theme', :theme => theme
end
