require "csv"
require 'yaml'

jupiter_item_uuid = File.open('tmp/jupiter_item_uuid.map', 'w')
hydranorth_item_noid  = File.open('tmp/hydranorth_item_noid.map', 'w')
fedora3_item_uuid = File.open('tmp/fedora3_item_uuid.map', 'w')

CSV.foreach("tmp/scholaris_items.csv", headers: true) do |row|
  jupiter_item_uuid.write "#{row['metadata.ual.jupiterId']} https://ualberta-dev.scholaris.ca/handle/#{row['handle']}\n"
  hydranorth_item_noid.write "#{YAML.load(row['metadata.ual.hydraNoid']).first} https://ualberta-dev.scholaris.ca/handle/#{row['handle']}\n" if row['metadata.ual.hydraNoid']
  fedora3_item_uuid.write "#{YAML.load(row['metadata.ual.fedora3UUID']).first} https://ualberta-dev.scholaris.ca/handle/#{row['handle']}\n" if row['metadata.ual.fedora3UUID']
end

jupiter_item_uuid.close
hydranorth_item_noid.close
fedora3_item_uuid.close