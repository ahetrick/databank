require 'rails_helper'

RSpec.describe Dataset, type: :model do

  #pending "add some examples to (or delete) #{__FILE__}"

  describe '#plain_text_citation' do

    dataset = FactoryGirl.create(:dataset, title: "Test Dataset")
    creator = FactoryGirl.create(:creator, family_name: "Fallaw", given_name: "Colleen", dataset_id: dataset.id)
    
    it "returns a string in the expected format" do
      allow(dataset).to receive(:creators).and_return([creator])
      expect(dataset.plain_text_citation.strip).to eq("Fallaw, Colleen (#{Time.new.year}): Test Dataset. University of Illinois at Urbana-Champaign.".strip)
    end

  end


end
