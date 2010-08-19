class MainController < ApplicationController

  def index
    
  end
  
  def poligraft
    source_url = params[:url].gsub(/\?/, '-')
    if (@result = Result.create!(:source_url => source_url, :source_text => params[:text]))
      @result.process_entities
      if params[:json] == "1"
        redirect_to "/" + @result.slug + ".json"
      else
        redirect_to "/" + @result.slug
      end
    else
      flash[:error] = "Sorry, couldn't process that input."
      redirect_to :root
    end
  end
  
  def result
    @result = Result.first(:slug => params[:slug])
    if @result
      response_code = @result.processed ? 200 : 202

      respond_to do |format|
        format.html
        format.json { render :json => @result.to_json(:methods  => [:source_content],
                                                      :except   => [:source_text]),
                             :status => response_code }
      end
    else
      render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404
    end
  end
  
  def feedback
    
    if params[:feedback]
      @feedback = Feedback.create(params[:feedback])
      if @feedback.save
        Notifier.feedback_email(@feedback).deliver
        redirect_to thanks_path
      else
        flash[:error] = "Error saving. Please fill in all fields."
      end
    else
      @feedback = Feedback.new
    end
  end
    
  def about
    
  end
  
  def plucked
    urls = ['http://www.nytimes.com/2010/05/06/opinion/06gcollins.html',
            'http://www.politico.com/news/stories/0610/38121.html',
            'http://www.theatlantic.com/politics/archive/2010/07/wikileak-ethics/60660/',
            'http://www.cbsnews.com/stories/2010/07/15/politics/main6681481.shtml',
            'http://www.huffingtonpost.com/2010/08/07/theresa-riggi-american-mo_n_674423.html',
            'http://www.latimes.com/business/la-fi-financial-reform-20100716,0,2303004.story',
            'http://www.washingtonpost.com/wp-dyn/content/article/2010/07/30/AR2010073000806.html']

    @articles = urls.map { |url| ContentPlucker.pluck_from url }
  end
  
end