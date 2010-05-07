module ApplicationHelper

  def formatted_content(result)
    highlight(result.source_content.html_safe,
              result.entities.map {|e| e.name },
              :highlighter => '<span class="highlight">\1</span>')
  end

end
