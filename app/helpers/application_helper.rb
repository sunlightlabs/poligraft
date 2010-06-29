module ApplicationHelper

  def formatted_content(result)
    content = highlight(result.source_content.html_safe,
              result.entities.map {|e| e.name if e.entity_type == "Person" && e.tdata_id }.compact!,
              :highlighter => '<span class="person">\1</span>')
    highlight(content,
              result.entities.map {|e| e.name if (e.entity_type == "Organization" || e.entity_type == "Company") && e.tdata_id }.compact!,
              :highlighter => '<span class="organization">\1</span>')
  end

  def influence_explorer_url(entity)
    "http://brisket.transparencydata.com/#{entity.tdata_type}/#{entity.tdata_slug}/#{entity.tdata_id}" 
  end
end
