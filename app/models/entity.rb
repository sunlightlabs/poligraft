class Entity
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :entity_type, String
  key :relevance, Float
  key :tdata_id, String
  key :tdata_type, String
  key :tdata_slug, String
  key :tdata_count, Integer
  key :contributor_breakdown, Hash
  key :recipient_breakdown, Hash
  
  
  many :contributors
end