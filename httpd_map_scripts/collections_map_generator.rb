require "csv"
require 'json'

jupiter_collection_uuid = File.open('tmp/jupiter_collection_uuid.map', 'w')
hydranorth_community_collection_noid  = File.open('tmp/hydranorth_community_collection_noid.map', 'a')
fedora3_collection_uuid = File.open('tmp/fedora3_collection_uuid.map', 'w')

CSV.foreach("tmp/scholaris_collections.csv", headers: true) do |row|
  jupiter_collection_uuid.write "#{row['provenance.ual.jupiterId.collection']} https://ualberta-dev.scholaris.ca/handle/#{row['handle']}\n"

  provenance = JSON.parse(row['metadata.dc.provenance.0.value']) if row['metadata.dc.provenance.0.value']
  hydranorth_community_collection_noid.write "#{provenance['ual.hydraNoid.collection']} https://ualberta-dev.scholaris.ca/handle/#{row['handle']}\n" if provenance && provenance['ual.hydraNoid.collection']
  fedora3_collection_uuid.write "#{provenance['ual.fedora3UUID.collection']} https://ualberta-dev.scholaris.ca/handle/#{row['handle']}\n" if provenance && provenance['ual.fedora3UUID.collection']
end

jupiter_collection_uuid.close
fedora3_collection_uuid.close
hydranorth_community_collection_noid.close