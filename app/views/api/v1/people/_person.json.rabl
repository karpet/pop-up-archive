# wonky explicit syntax because RABL doesn't seem to treat
# Elasticsearch::Model::Response::Result objects like ActiveRecord objects
# so 'attributes' does not work as expected.
if @object.is_a? Person
  attributes :name, :id
else
  return { :name => @object.name, :id => @object.id }
end
