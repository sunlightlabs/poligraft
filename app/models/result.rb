class Result

  include MongoMapper::Document

  key :source_url, String
  key :source_title, String
  key :source_text, Binary
  key :source_format, String
  key :source_hash, String
  key :slug, String
  key :status, String
  key :contribution_count, Integer, :default => 0
  key :processed, Boolean, :default => false
  key :suppress_text, Boolean, :default => false
  timestamps!

  many :entities

  ensure_index :slug
  ensure_index :source_url

  validates_presence_of :source_title
  validates_presence_of :source_text
  validates_presence_of :source_format
  validates_presence_of :slug
  validates_presence_of :source_hash
  validates_uniqueness_of :slug

  before_validation :ensure_slug, :ensure_source_title_text, :ensure_hash
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

  def ensure_source_title_text
    return unless self.source_format.blank?
    self.source_format = 'plain_text'
    self.source_title = self.source_content[0..30] + "..."
    if self.source_content.blank?
      raise "Must set source_url or source_content" if self.source_url.blank?
      self.source_text = ContentPlucker.pluck_from(self.source_url)
      self.source_title = ContentPlucker.pluck_title_from(self.source_url)
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
    self.source_text = '' if self.suppress_text == true
    self.save
  end

  def extract_entities
    json_string = Calais.enlighten( :content => self.source_content,
                                    :content_type => (self.source_url.blank? ? :raw : :html),
                                    :output_format => :json,
                                    :license_id => KEYS["calais"] )
    json = JSON.parse(json_string)
    desired_types = %w{Person Organization Company}
    names_to_suppress = ["white house", "house", "senate", "congress", "assembly", "supreme court",
                         "legislature", "state senate", "administration", "obama administration",
                         "republicans", "republican party", "democrats", "democratic party"]
    json.each do |k,v|
      if v["_typeGroup"] == "entities" &&
         desired_types.include?(v["_type"]) &&
         !names_to_suppress.include?(v["name"].downcase)

        unless v["_type"] == "Person" && !v["name"].include?(' ')

          self.entities << Entity.new(:entity_type => v["_type"],
                                      :name => v["name"],
                                      :relevance => v["relevance"])
        end
      end
    end
    self.status = "Entities Extracted"
    self.save
  end

  def link_entities
    hydra = Typhoeus::Hydra.new
    tdata = TransparencyData::Client.new(hydra)
    self.entities.each do |entity|
      tdata.entities(:search => entity.name) do |results, error|
        if error
          Rails.logger.info "Error in link_entities: #{error}"
        else
          results.each do |result|
            if (result['type'] == "politician" && entity.entity_type == "Person") ||
               (result['type'] == "individual" && entity.entity_type == "Person") ||
               (result['type'] == "organization" && entity.entity_type == "Company") ||
               (result['type'] == "organization" && entity.entity_type == "Organization")

              if entity.tdata_count.nil? ||
                entity.tdata_count < (result.count_given.to_i + result.count_received.to_i)

                entity.tdata_name = result.name
                entity.tdata_type = result['type']
                entity.tdata_id = result.id
                entity.tdata_slug = result.name.parameterize
                entity.tdata_count = result.count_given + result.count_received
                entity.save
              end
            end
          end # results.each
        end # if error
      end # tdata.entities
    end # self.entities.each
    hydra.run

    hydra2 = Typhoeus::Hydra.new
    tdata2 = TransparencyData::Client.new(hydra2)
    self.entities.each do |entity|

      if entity.tdata_type == "politician" && entity.tdata_count > 0
        tdata2.local_breakdown(entity.tdata_id) do |breakdown, error|
          add_breakdown(breakdown, entity, :first   => "in_state",
                                                    :second  => "out_of_state",
                                                    :type    => "contributor")
        end
        tdata2.contributor_type_breakdown(entity.tdata_id) do |breakdown, error|
          add_breakdown(breakdown, entity, :first   => "individual",
                                                    :second  => "pac",
                                                    :type    => "contributor")
        end

        tdata2.top_sectors(entity.tdata_id, :limit => 6) do |sectors, error|

          sectors.each do |sector|
            if entity.top_industries.length < 3 &&
               sector.name != "Other" && sector.name != "Unknown" &&
               sector.name != "Administrative Use"
              entity.top_industries << sector.name
            end
          end

        end
      elsif entity.tdata_type == "individual" && entity.tdata_count > 0
        tdata2.individual_party_breakdown(entity.tdata_id) do |breakdown, error|
          add_breakdown(breakdown, entity, :first   => "dem",
                                                    :second  => "rep",
                                                    :type    => "recipient")
        end
      elsif entity.tdata_type == "organization" && entity.tdata_count > 0
        tdata2.org_party_breakdown(entity.tdata_id) do |breakdown, error|
          add_breakdown(breakdown, entity, :first   => "dem",
                                                    :second  => "rep",
                                                    :type    => "recipient")
        end
      end
      entity.save
    end
    hydra2.run

    self.status = "Entities Linked"
    self.save

  end

  def find_contributors
    hydra = Typhoeus::Hydra.new(:max_concurrency => 1)
    tdata = TransparencyData::Client.new(hydra)
    self.entities.each do |recipient|
      if recipient.tdata_type == 'politician'
        self.entities.each do |contributor|
          unless contributor.tdata_id.blank? || contributor.tdata_type == 'politician'
            Rails.logger.info "recipient: #{recipient.tdata_id} | contributor: #{contributor.tdata_id}"
            tdata.recipient_contributor_summary(recipient.tdata_id, contributor.tdata_id) do |summary, error|
              if error
                Rails.logger.info "Error in find_contributors: #{error}"
              elsif summary.amount.to_i > 0
                recipient.contributors << Contributor.new(:tdata_name => summary.contributor_name,
                                                          :extracted_name => contributor.name,
                                                          :amount => summary.amount,
                                                          :tdata_id => contributor.tdata_id,
                                                          :tdata_type => contributor.tdata_type,
                                                          :tdata_slug => contributor.tdata_slug)
                self.contribution_count += 1
              end
            end
          end # unless contributor.tdata_id.blank?
        end # if self.entities.each do |contributor|
        recipient.save
      end # if recipient.tdata_type
    end # self.entities.each do |recipient|
    hydra.run
    self.status = "Contributors Identified"
    self.processed = true
    self.save
  end

  def add_breakdown(breakdown, entity, params)
    first = breakdown.send("#{params[:first]}_amount").to_i
    second = breakdown.send("#{params[:second]}_amount").to_i
    sum = first + second
    sum = 1 if sum == 0
    entity.send("#{params[:type]}_breakdown")[params[:first]] = (first * 100) / sum
    entity.send("#{params[:type]}_breakdown")[params[:second]] = (second * 100) / sum
    entity.save
  end

  handle_asynchronously :process_entities

end
