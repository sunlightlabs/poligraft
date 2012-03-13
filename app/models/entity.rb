class Entity
  include MongoMapper::EmbeddedDocument

  key :tdata_id, String
  key :name, String
  key :entity_type, String
  key :slug, String
  key :count, Integer
  key :contributor_breakdown, Hash
  key :recipient_breakdown, Hash
  key :top_industries, Array

  many :contributors
end