module ApplicationHelper

  def highlight_entities(text, phrases)
    if text.blank? || phrases.blank?
      text
    else
      match = phrases.map {|p| Regexp.escape(p) }.join('|')
      text.gsub(/(#{match})(?![^<]*?>)/i) do |match|
        "<span class='highlight' data-entity='#{match.parameterize}'>#{match}</span>"
      end
    end.html_safe
  end

  def formatted_content(result)
    text = result.source_content.html_safe
    phrases = result.entities.map {|e| e.matched_names if e.tdata_id }.flatten.compact rescue []
    highlight_entities(text, phrases)
  end

  def influence_explorer_url(entity)
    "http://influenceexplorer.com/#{entity.tdata_type}/#{entity.tdata_slug}/#{entity.tdata_id}"
  end

  def piechart_url(entity)
    url = "http://chart.apis.google.com/chart?cht=p&chf=bg,s,F3F4EE&chp=1.57"

    if entity.tdata_type == "politician"
      url += "&chs=140x50"
      url += "&chco=ABDEBF|169552"
      url += "&chd=t:#{entity.contributor_breakdown['individual']},#{entity.contributor_breakdown['pac']}"
      url += "&chdl=Individuals|PACs"
    elsif (entity.tdata_type == "organization" || entity.tdata_type == "individual")
      url += "&chs=145x50"
      url += "&chco=3072F3|DB2A3F"
      url += "&chd=t:#{entity.recipient_breakdown['dem']},#{entity.recipient_breakdown['rep']}"
      url += "&chdl=Democrats|Republicans"
    end

    url
  end
end
