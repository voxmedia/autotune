json.array!(@blueprints) do |blueprint|
  json.partial! 'autotune/blueprints/blueprint', :blueprint => blueprint
end
