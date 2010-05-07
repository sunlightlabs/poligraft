class Entity
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :entity_type, String
  key :relevance, Float
  
end