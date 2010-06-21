require 'spec_helper'

describe Result do
    
  context "before validation" do

    let(:result) { Result.new }
  
    it "sets a four character slug" do
      result.ensure_slug
      result.slug.should match /[a-zA-z0-9]{4}/
    end
    
    it "throws an error if neither content nor URL are set" do
      expect {
        result.validate 
      }.to raise_error
    end
  
    it "generates an MD5 hash based on source_text" do
      result.source_text = "Lorem ipsum dolor sit amet"
      result.ensure_hash
      result.source_hash.should == Digest::MD5.hexdigest(result.source_content)
    end
  end
end
