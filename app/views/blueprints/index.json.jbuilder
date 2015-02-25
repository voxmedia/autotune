json.array!(@blueprints) do |blueprint|
  json.partial! 'blueprints/blueprint', :blueprint => blueprint
end
