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
    url = "http://chart.apis.google.com/chart?cht=p&chf=bg,s,F3F4EE&chp=1.57&chs=140x50"

    if entity.contributor_breakdown && (entity.contributor_breakdown['pac'] || entity.contributor_breakdown['individual'])
      url += "&chco=ABDEBF|169552"
      url += "&chd=t:#{entity.contributor_breakdown['individual']},#{entity.contributor_breakdown['pac']}"
      url += "&chdl=Individuals|PACs"
    elsif entity.contributor_breakdown && (entity.contributor_breakdown['in_state'] || entity.contributor_breakdown['out_of_state'])
      url += "&chco=ABDEBF|169552"
      url += "&chd=t:#{entity.contributor_breakdown['in_state']},#{entity.contributor_breakdown['out_of_state']}"
      url += "&chdl=In+State|Out+of+State"
    elsif entity.recipient_breakdown && (entity.recipient_breakdown['dem'] || entity.recipient_breakdown['rep'])
      url += "&chco=3072F3|DB2A3F"
      url += "&chd=t:#{entity.recipient_breakdown['dem']},#{entity.recipient_breakdown['rep']}"
      url += "&chdl=Democrats|Republicans"
    else
      url = '#'
    end

    url
  end

  def superlatives_for(type, title, entity)
    if entity.send(type).any?
      render "main/superlative_list", :type => type, :title => title, :superlatives => (entity.send(type) rescue [])
    end
  end

end
