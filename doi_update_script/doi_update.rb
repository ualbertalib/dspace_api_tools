require 'csv'
require 'uri'
require 'net/http'
require 'cgi'

require 'active_record'
require 'pry'
require 'sqlite3'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db.sqlite3'
)

class Item < ActiveRecord::Base

  def updatate_doi
    url = URI("https://api.test.datacite.org/dois/#{CGI.escape(doi)}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Put.new(url)
    request["accept"] = 'application/vnd.api+json'
    request["content-type"] = 'application/json'
    request.basic_auth(ENV['DATACITE_USERNAME'], ENV['DATACITE_PASSWORD'])
    request.body = "{\"data\":{\"type\":\"dois\",\"attributes\":{\"url\":\"https://ualberta-dev.scholaris.ca/handle/#{handle}\"}}}"

    puts request.to_hash
    puts request.body
    #response = http.request(request)
    #puts response.read_body
  end
end

@first_run = !Item.table_exists?

# Create the table (migration-like setup)
if @first_run
  ActiveRecord::Schema.define do
    create_table :items do |t|
      t.string :doi
      t.string :handle
      t.string :status
      t.string :error_message
      t.timestamps
    end
    add_index :items, :doi, unique: true
    add_index :items, :handle, unique: true
  end
end

# initialize the database
if Item.count == 0
  CSV.foreach("tmp/scholaris_items.csv", headers: true) do |row|
    binding.pry
    next unless row['metadata.dc.identifier.doi']
    doi = row['metadata.dc.identifier.doi'].sub("https://doi.org/", "")[0]
    unless Item.exists?(doi: doi)
      item = Item.new(doi: doi, handle: row['handle'], status: 'pending') 
      item.save
      print '.'
    end
  end
end

binding.pry