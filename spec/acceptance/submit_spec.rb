require 'spec_helper'

feature "Submit an entry to poligraft", %q{
  In order to run poligraft
  As a visitor
  I want to submit text or a URL to be truthified
} do
  
  scenario "Submit block of text" do
    visit '/'
    fill_in 'Or, paste in the text:', :with => "Lorem ipsum dolor sit amet"
    click "Run Poligraft"
    find('h2#page_title').text.should == "Results"
  end
  
end