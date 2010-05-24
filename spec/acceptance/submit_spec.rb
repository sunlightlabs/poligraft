require 'spec_helper'

feature "Submit an entry to be truthified", %q{
  In order to truthify me
  As a visitor
  I want to submit text or a URL to be truthified
} do
  
  scenario "Submit block of text" do
    visit '/'
    fill_in 'Or, paste in the text:', :with => "Lorem ipsum dolor sit amet"
    click "Truthify!"
    find('h2#page_title').text.should == "Results"
  end
  
end