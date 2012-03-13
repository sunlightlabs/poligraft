require 'spec_helper'

feature "Submit an entry to poligraft", %q{
  In order to run poligraft
  As a visitor
  I want to submit text or a URL to be truthified
} do

  scenario "Submit block of text" do
    visit '/'
    fill_in 'text', :with => "Lorem ipsum dolor sit amet"
    click_button 'submit'
    find('#source_content p').text.should == "Lorem ipsum dolor sit amet"
  end

end