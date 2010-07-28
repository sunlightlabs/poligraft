class Feedback
  
  include MongoMapper::Document
  
  key :name, String
  key :email, String
  key :slug, String
  key :message, String
  timestamps!

  validates_presence_of :name
  validates_presence_of :email
  validates_presence_of :message

end