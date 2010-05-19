class Result

  include MongoMapper::Document

  key :source_url, String
  key :source_text, Binary
  key :source_format, String
  key :source_hash, String
  key :slug, String

  many :entities

  validates_presence_of :source_text
  validates_presence_of :slug
  validates_uniqueness_of :slug
  
  before_validation :set_slug, :ensure_source_text
  before_save :process_entities

  def source_content
    self.source_text.to_s
  end

  protected
  
  def set_slug
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + (1..9).to_a
    begin
      self.slug = chars.sort_by {rand}[0,4].join
    end while (Result.first(:slug => self.slug))
  end

  def ensure_source_text
    self.source_format = 'plain_text'
    if self.source_content.blank?
      self.source_text = pluck_article(self.source_url)
      self.source_format = 'html'
    end
    unless self.source_text.blank?
       self.source_hash = Digest::MD5.hexdigest(self.source_content)
    end
  end

  def process_entities
    json_string = Calais.enlighten( :content => self.source_content,
                                    :content_type => (self.source_url.blank? ? :raw : :html),
                                    :output_format => :json,
                                    :license_id => KEYS["calais"] )
    json = JSON.parse(json_string)
    entities = []
    desired_types = %w{Person Organization Company}
    json.each do |k,v|
      if v["_typeGroup"] == "entities" && desired_types.include?(v["_type"])
        self.entities << Entity.new(:entity_type => v["_type"],
                                    :name => v["name"],
                                    :relevance => v["relevance"])
      end
    end
  end

  def pluck_article(url)

    # get the raw HTML
    doc = Nokogiri::HTML.parse(open(url), url, "UTF-8")

    # delete stuff
    doc.search('img').remove
    doc.search('script').remove

    # get the paragraphs
    paragraphs = doc.search('p')

    # assign points to the parent nodes for each paragraph
    parents = {}
    paragraphs.each do |paragraph|
      points = calculate_points(paragraph)
      if parents.has_key?(paragraph.parent)
        parents[paragraph.parent] += points
      else
        parents[paragraph.parent] = points
      end
    end

    # get the parent node with the highest point total
    winner = parents.sort{ |a,b| a[1] <=> b[1] }.last[0]

    # return the plucked HTML content
    winner_paragraphs = ""
    winner.search('./p').each do |n| 
      winner_paragraphs = winner_paragraphs + "<p>#{n.inner_html}</p>"
    end
    "<h4>" + doc.search('title').inner_html + "</h4>" + winner_paragraphs
  end


  def calculate_points(paragraph, starting_points = 0)

    # reward for being a new paragraph
    points = starting_points + 20

    # look at the id and class of paragraph and parent
    classes_and_ids = (paragraph.get_attribute('class') || '') + ' ' +
                      (paragraph.get_attribute('id') || '') + ' ' +
                      (paragraph.parent.get_attribute('class') || '') + ' ' +
                      (paragraph.parent.get_attribute('id') || '')

    # deduct severely and return if clearly not content
    if classes_and_ids =~ /comment*|meta|footer|footnote/
      points -= 5000
      return points
    end

    # reward if probably content
    if classes_and_ids =~ /post|hentry|entry|article|story.*/
      points += 500
    end

    # look at the actual text of the paragraph
    content = paragraph.content

    # deduct if very short
    if content.length < 20
      points -= 50
    end

    # reward if long
    if content.length > 100
      points += 50
    end

    # deduct if no periods, question marks, or exclamation points
    unless (content.include?('.') or content.include?('?') or content.include?('!'))
      points -= 100
    end

    # reward for periods and commas
    points += content.count('.') * 10
    points += content.count(',') * 20

    points

  end

end