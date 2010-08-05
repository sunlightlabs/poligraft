class Notifier < ActionMailer::Base

  def feedback_email(feedback)
    @message = feedback.message
    @slug = feedback.slug
    mail :from => "#{feedback.name} <#{feedback.email}>", 
         :to => 'poligraft@sunlightfoundation.com',
         :subject => "Poligraft Feedback"
  end

end
