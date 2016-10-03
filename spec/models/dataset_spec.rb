require 'rails_helper'

RSpec.describe Dataset, type: :model do

  fixtures :users, :creators, :datasets

  #pending "add some examples to (or delete) #{__FILE__}"

  describe '#plain_text_citation' do

    let(:draft_1){datasets(:dataset_draft_1)}

    it "returns a string in the expected format" do
      expect(draft_1.plain_text_citation.strip).to eq('Fallaw, Colleen (2016): Another Test. University of Illinois at Urbana-Champaign.'.strip)
    end

  end


end
