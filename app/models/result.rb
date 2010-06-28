class Result

  include MongoMapper::Document

  key :source_url, String
  key :source_text, Binary
  key :source_format, String
  key :source_hash, String
  key :slug, String
  key :status, String

  many :entities

  validates_presence_of :source_text
  validates_presence_of :slug
  validates_presence_of :source_hash
  validates_uniqueness_of :slug
  
  before_validation :ensure_slug, :ensure_source_text, :ensure_hash
  before_create :set_status
  
  def source_content
    self.source_text.to_s
  end

  def ensure_slug    
    return unless self.slug.blank?
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + (1..9).to_a
    begin
      self.slug = chars.sort_by {rand}[0,4].join
    end while (Result.first(:slug => self.slug))
  end

  def ensure_source_text
    return unless self.source_format.blank?
    self.source_format = 'plain_text'
    if self.source_content.blank?
      raise "Must set source_url or source_content" if self.source_url.blank?
      self.source_text = pluck_article(self.source_url)
      self.source_format = 'html'
    end
  end

  def ensure_hash
    return unless self.source_hash.blank?
    unless self.source_content.blank?
      self.source_hash = Digest::MD5.hexdigest(self.source_content)
    end
  end
  
  def set_status
    self.status = "Text Plucked"
  end  

  def process_entities
    TransparencyData.api_key = KEYS["sunlight"]
    TransparencyData.api_domain = KEYS["ie"] if KEYS["ie"]
    extract_entities
    link_entities
    find_contributors
  end

  def extract_entities
    json_string = Calais.enlighten( :content => self.source_content,
                                    :content_type => (self.source_url.blank? ? :raw : :html),
                                    :output_format => :json,
                                    :license_id => KEYS["calais"] )
    json = JSON.parse(json_string)
    desired_types = %w{Person Organization Company}
    names_to_suppress = ["white house", "house", "senate", "congress", "assembly", 
                         "legislature", "state senate", "administration", "obama administration"]
    json.each do |k,v|
      if v["_typeGroup"] == "entities" && 
         desired_types.include?(v["_type"]) && 
         !names_to_suppress.include?(v["name"].downcase)
        
        self.entities << Entity.new(:entity_type => v["_type"],
                                    :name => v["name"],
                                    :relevance => v["relevance"])
      end
    end
    self.status = "Entities Extracted"
    self.save
  end

  handle_asynchronously :process_entities

end