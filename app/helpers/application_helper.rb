module ApplicationHelper

  def formatted_content(result)
    highlight(result.source_content.html_safe,
              result.entities.map {|e| e.name },
              :highlighter => '<span class="highlight">\1</span>')
  end

  def influence_explorer_url(entity)
    "http://brisket.transparencydata.com/#{entity.tdata_type}/#{entity.tdata_slug}/#{entity.tdata_id}" 
  end
end
