class MainController < ApplicationController

  def index
    
  end
  
  def poligraft
    if (@result = Result.create!(:source_url => params[:url], :source_text => params[:text]))
      @result.process_entities
      redirect_to "/" + @result.slug
    else
      flash[:error] = "Sorry, couldn't process that input."
      redirect_to :back
    end
  end
  
  def result
    @result = Result.first(:slug => params[:slug])
    respond_to do |format|
      format.html
      format.json { render :json => @result.to_json(:methods  => [:source_content],
                                                    :except   => [:source_text]) }
    end
  end
  
  def feedback
    
    if params[:feedback]
      @feedback = Feedback.create(params[:feedback])
      if @feedback.save
        Notifier.feedback_email(@feedback).deliver
        flash[:notice] = "Thanks! Your message has been recorded."
        redirect_to feedback_path
      else
        flash[:error] = "Error saving. Please fill in all fields."
      end
    else
      @feedback = Feedback.new
    end
  end
    
  def about
    
  end
  
end