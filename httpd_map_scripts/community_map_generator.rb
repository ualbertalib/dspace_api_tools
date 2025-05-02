require "csv"

jupiter_community_uuid = File.open('tmp/jupiter_community_uuid.map', 'w')
hydranorth_community_collection_noid  = File.open('tmp/hydranorth_community_collection_noid.map', 'w')
fedora3_community_uuid = File.open('tmp/fedora3_community_uuid.map', 'w')

CSV.foreach("tmp/historical_community_ids.csv", headers: true) do |row|
  jupiter_community_uuid.write "#{row['jupiter id']} #{row['Scholaris Link']}\n"
  hydranorth_community_collection_noid.write "#{row['hydra noid']} #{row['Scholaris Link']}\n" if row['hydra noid']
  fedora3_community_uuid.write "#{row['fedora3 uuid']} #{row['Scholaris Link']}\n" if row['fedora3 uuid']
end

jupiter_community_uuid.close
fedora3_community_uuid.close
hydranorth_community_collection_noid.close