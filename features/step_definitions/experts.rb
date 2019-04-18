require 'net/http'
require 'uri'

Then("I see valid xml on the Illinois Experts page") do
  page_content = open('/illinois_experts.xml')
end

private

def open(url)
  Net::HTTP.get(URI.parse(url))
end