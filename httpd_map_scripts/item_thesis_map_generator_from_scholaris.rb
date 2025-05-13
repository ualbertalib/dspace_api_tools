require 'csv'

hydranorth_item_noid  = File.open('tmp/hydranorth_item_noid.map', 'w')
fedora3_item_uuid = File.open('tmp/fedora3_item_uuid.map', 'w')

CSV.foreach("tmp/historical_item_ids.csv", headers: true) do |row|
  next if row['scholaris handle'] == '#N/A'
  hydranorth_item_noid.write "#{row['hydra noid']} #{row['scholaris handle']}\n" if row['hydra noid']
  fedora3_item_uuid.write "#{row['fedora3 uuid']} #{row['scholaris handle']}\n" if row['fedora3 uuid']
end

hydranorth_item_noid.close
fedora3_item_uuid.close