# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

License.create(code: "CC01", name: "CC0 1.0 waiver", external_info_url: "https://creativecommons.org/about/cc0", full_text_url: "#{Rails.root}/public/CC01.txt")
License.create(code: "CCBY4", name: "CC BY 4.0 license", external_info_url: " https://creativecommons.org/licenses/by/4.0", full_text_url: "#{Rails.root}/public/CCBY4.txt")
License.create(code: "license.txt", name: "See license.txt file in dataset")