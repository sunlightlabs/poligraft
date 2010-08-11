module ApplicationHelper

  def formatted_content(result)
    highlight(result.source_content.html_safe,
              result.entities.map {|e| e.name if e.tdata_id }.compact!,
              :highlighter => '<span class="highlight" data-entity="\1">\1</span>')
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
