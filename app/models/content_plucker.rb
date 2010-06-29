class ContentPlucker
  
  def self.pluck_title_from(url)
    doc = Nokogiri::HTML.parse(open(url), url, "UTF-8")
    doc.search('title').inner_html
  end
  
  def self.pluck_from(url)

    # get the raw HTML
    doc = Nokogiri::HTML.parse(open(url), url, "UTF-8")

    # remove undesirable tags
    doc.search('img').remove
    doc.search('script').remove
    doc.search('style').remove
    doc.search('a').each { |n| n.replace(n.nil? ? "" : n.inner_html) }

    paragraphs = doc.search('p')

    # assign points to the parent nodes for each paragraph
    parents = {}
    paragraphs.each do |paragraph|
      points = self.calculate_points(paragraph)
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


  def self.calculate_points(paragraph, starting_points = 0)

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