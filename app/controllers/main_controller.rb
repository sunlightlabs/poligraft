class MainController < ApplicationController

  def index
    
  end
  
  def truthify
    if (@result = Result.create!(:source_url => params[:url], :source_text => params[:text]))
      @result.process_entities
      redirect_to "/" + @result.slug
    else
      flash[:error] = "Sorry, couldn't truthify that input."
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
  
end