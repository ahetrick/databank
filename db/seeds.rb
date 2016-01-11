# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

cc01 = License.find_or_initialize_by(code: "CC01")
cc01.name = "CC0"
cc01.external_info_url = "https://creativecommons.org/about/cc0"
cc01.full_text_url = "#{Rails.root}/public/CC01.txt"
cc01.save!

cc0BY4 = License.find_or_initialize_by(code: "CCBY4")
cc0BY4.name = "CC BY"
cc0BY4.external_info_url = "https://creativecommons.org/licenses/by/4.0"
cc0BY4.full_text_url = "#{Rails.root}/public/CCBY4.txt"
cc0BY4.save!

custom = License.find_or_initialize_by(code: "license.txt")
custom.name = "See license.txt file in dataset"
custom.save!