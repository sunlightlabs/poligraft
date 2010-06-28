class Contributor
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :amount, Integer
  key :tdata_id, String
  key :tdata_type, String
  key :tdata_slug, String
    
end