require 'rake'

namespace :databank do

  desc 'delete all datasets'
  task :delete_all => :environment do
    Dataset.all.each do |dataset|
      dataset.destroy
    end

  end


  desc 'Import sample datasets'
  task :sample_import => :environment do


    ds2 = Dataset.new :identifier => %Q[10.13012/J8Z60KZG],
                      :title => "Honey bee brain images processed to reveal c-jun mRNA",
                      :license => "Copyright © (2014), University of Illinois. All rights reserved. License Placeholder Text",
                      :description => %Q[Immediate early genes (IEG) have served as useful markers of brain neuronal activity in mammals, and more recently in insects. The mammalian canonical IEG, c-jun, is part of regulatory pathways conserved in insects and has been shown to be responsive to alarm pheromone in honey bees. We tested whether c-jun is responsive in honey bees to another behaviorally relevant stimulus, sucrose, in order to further identify brain regions involved in sucrose processing. To identify responsive regions, we developed a new method of voxel-based analysis of c-jun mRNA expression. We found that c-jun is expressed in somata throughout the brain. It was rapidly induced in response to sucrose stimuli, and it responded in somata near the antennal and mechanosensory motor center, mushroom body calices, and lateral protocerebrum, which are known to be involved in sucrose processing. c-jun also responded to sucrose in somata near the lateral subesophageal ganglion, dorsal optic lobe, ventral optic lobe, and dorsal posterior protocerebrum, which had not been previously identified by other methods. These results demonstrate the utility of voxel-based analysis of mRNA expression in the insect brain.],
                      :publication_year => "2014",
                      :publisher => "University of Illinois at Urbana-Champaign"

    ds2.save!

    c1 = Creator.new :creator_name => "McNeill, Matthew S.", :identifier => ["http://orcid.org/0000-0002-6610-0376"],  :dataset_id => ds2.id
    c2 = Creator.new :creator_name => "Robinson, Gene E.", :identifier => ["http://orcid.org/0000-0003-4828-4068"], :dataset_id => ds2.id

    c1.save!
    c2.save!

    ds2.creator_ordered_ids = "#{c1.id},#{c2.id}"

    ds2.save!

    ds1 = Dataset.new :identifier => %Q[10.9999/dev/test1],
                      :license => "Copyright © (2014), University of Illinois. All rights reserved. License Placeholder Text",
                      :title => %Q[Data from "Digital Preservation File Format Policies of ARL Member Libraries: An Analysis"],
                      :description => %Q[Whether overseeing institutional repositories, digital library collections, or digital preservation services, repository managers often establish file format policies intended to extend the longevity of collections under their care. While concerted efforts have been made in the library community to encourage common standards, digital preservation policies regularly vary from one digital library service to another. In the interest of gaining a broad view of contemporary digital preservation practice in North American research libraries, this paper presents the findings of a study of file format policies at Association of Research Libraries (ARL) member institutions. It is intended to present the digital preservation community with an assessment of the level of trust currently placed in common file formats in digital library collections and institutional repositories. Beginning with a summary of file format research to date, the authors describe the research methodology they used to collect and analyze data from the file format policies of ARL Library repositories and digital library services. The paper concludes with a presentation and analysis of findings that explore levels of confidence placed in image, text, audio, video, tabular data, software application, presentation, geospatial, and computer program file formats. The data show that file format policies have evolved little beyond the document and image digitization standards of traditional library reformatting programs, and that current approaches to file format policymaking must evolve to meet the challenges of research libraries' expanding digital repository services.],
                      :publication_year => "2014",
                      :publisher => "University of Illinois at Urbana-Champaign"
    ds1.save!

    c1 = Creator.new :creator_name => "Rimkus, Kyle R.", :identifier =>["http://orcid.org/0000-0002-9142-6677"], :dataset_id => ds1.id
    c2 = Creator.new :creator_name => "Padilla, Thomas",  :identifier =>["http://orcid.org/0000-0002-6743-6592"], :dataset_id => ds1.id
    c3 = Creator.new :creator_name => "Popp, Tracy", :dataset_id => ds1.id
    c4 = Creator.new :creator_name => "Martin, Greer", :dataset_id => ds1.id

    c1.save!
    c2.save!
    c3.save!
    c4.save
    ds1.creator_ordered_ids = "#{c1.id},#{c2.id},#{c3.id},#{c4.id}"
    ds1.save!

  end

  desc "Clear Rails cache (sessions, views, etc.)"
  task clear: :environment do
    Rails.cache.clear
  end

end