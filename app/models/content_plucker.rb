# Algorithm heavily inspired by arc90's Readability:
#
# http://lab.arc90.com/experiments/readability/
# http://code.google.com/p/arc90labs-readability/source/browse/trunk/js/readability.js
#
class ContentPlucker

  def self.pluck_title_from(url)
    begin
      doc = Nokogiri::HTML.parse(_get_request_for(url), url, "UTF-8")
    # rescue
      # return "Cannot load URL"
    end
    doc.search('title').inner_html
  end

  def self.pluck_from(url)
    begin
      doc = Nokogiri::HTML.parse(_get_request_for(url), url, "UTF-8")
    # rescue
      # return "<h2>Cannot load URL</h2><p>Poligraft is unable to load that URL.</p><p>Please copy and paste the text into the <a href='/'>text area on the front page</a>."
    end
    # set up attribution
    favicon = ''
    response_code = Net::HTTP.get_response(URI.parse("http://#{pluck_domain(url)}/favicon.ico")).code.to_i
    if (response_code >= 200 && response_code < 400)
      favicon = "<img width='16px' src='http://#{pluck_domain(url)}/favicon.ico' />&nbsp;"
    end
    attribution = "<p class='attribution'>Original Source: #{favicon}<a href='#{url}'>#{pluck_domain(url)}</a></p>"

    # remove undesirable elements
    %w{meta img script style input textarea}.each do |tag|
      doc.search(tag).remove
    end
    doc.search('a').each do |n|
      unless n.nil?
        begin
          n.replace(n.inner_html)
        rescue NoMethodError

        end
      end
    end
    doc.search('ul.breadcrumb').remove
    doc.search('div').each do |div|
      if div.get_attribute('id') =~ /(combx|comment|disqus|foot|menu|rss|shoutbox|sidebar|sponsor|ad-break|agegate|promo|list|photo|social|singleAd|adx|relatedarea)/i ||
         div.get_attribute('class') =~ /(combx|comment|disqus|foot|menu|rss|shoutbox|sidebar|sponsor|ad-break|agegate|promo|list|photo|social|singleAd|adx|relatedarea)/i
         div.remove
      end
    end

    # convert <div>s that should be <p>s into <div>s
    doc.search('div').each do |div|
      brs = 0
      div.children.each do |child|
        brs += 1 if child.name == 'br'
      end
      div.name = 'p' if brs > 2
    end

    # try to find common names for containing div
    parents = {}
    doc.search('div').each do |div|
      if div.get_attribute('id') =~ /\A(article|body|entry|hentry|page|post|text|blog|story)\z/
        parents[div] = 50000

      elsif div.get_attribute('id') =~ /(entrytext|story_content)/
        parents[div] = 75000
      end

    end

    paragraphs = doc.search('p')

    # assign points to the parent nodes for each paragraph
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
    winner_points = parents.sort{ |a,b| a[1] <=> b[1] }.last[1]

    # return the plucked HTML content
    winner_text = ""
    winner.search('.//p').each do |n|
      unless n.get_attribute('class') =~ /\A(summary|caption|posted|comment)\z/

        n.search('div').each do |div|
          div.remove
        end

        winner_text = winner_text + "<p>#{n.inner_html}</p>"
      end
    end

    if winner_text == ""
      winner_text = winner.inner_html
    end

    "<h2>" + doc.search('title').inner_html + "</h2>" + attribution + winner_text
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
    if classes_and_ids =~ /(comment|meta|footer|footnote|posted)/i
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
    points += content.count('<br') * 30

    points

  end

  def self.pluck_domain(url)
    url.split('/')[2]
  end

  def self._get_request_for(url)
    url = CGI::unescape(url)
    headers = {'User-Agent' => 'Googlebot-News'}
    HTTParty.get(url, :headers => headers).body
  end
end
