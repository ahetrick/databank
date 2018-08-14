# lib/api/base.rb
require 'roda'
require 'json'

module API
  class Base < Roda
    plugin :json
    plugin :all_verbs

    route do |r|
      r.on "v2" do
        r.get 'hello' do
          { hello: :world }
        end
      end
    end
  end
end
