json.array!(@builds) do |build|
  json.partial! 'builds/build', :build => build
end
