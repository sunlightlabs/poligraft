class Migrations

  def self.migrate_tdata_names

    results = Result.all
    results.each do |r|
      r.entities.each do |e|
        e.tdata_name = e.name if e.tdata_name.nil?
        e.contributors.each do |c|
          c.tdata_name = c.name if c.tdata_name.nil? && c.name
        end
      end
      r.save
    end
  end
  
end