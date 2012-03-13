class Entity
  include MongoMapper::EmbeddedDocument

  key :tdata_id, String
  key :tdata_name, String
  key :tdata_type, String
  key :tdata_slug, String
  key :count, Integer
  key :contributor_breakdown, Hash
  key :recipient_breakdown, Hash
  key :top_industries, Array

  many :contributors
end