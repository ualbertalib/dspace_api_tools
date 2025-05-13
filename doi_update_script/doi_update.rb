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

  def update_doi
    begin
      url = URI("https://api.datacite.org/dois/#{CGI.escape(doi)}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Put.new(url)
      request["accept"] = 'application/vnd.api+json'
      request["content-type"] = 'application/json'
      request.basic_auth(ENV['DATACITE_USERNAME'], ENV['DATACITE_PASSWORD'])
      request.body = "{\"data\":{\"type\":\"dois\",\"attributes\":{\"url\":\"https://ualberta-dev.scholaris.ca/handle/#{handle}\"}}}"

      response = http.request(request)
      if response.kind_of? Net::HTTPSuccess
        self.status = 'success'
      else
        self.status = 'fail'
      end
      self.response_message = response.body
      self.save
    rescue StandardError => e
      self.status = 'fail'
      self.error_message = e.message
      self.response_mesage = response.body if response
      save
    end
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
      t.string :response_message
      t.string :error_message
      t.timestamps
    end
    add_index :items, :doi, unique: true
    add_index :items, :handle, unique: true
  end
end

# initialize/update the database
CSV.foreach("tmp/historical_item_ids.csv", headers: true) do |row|
  next if row['scholaris handle'] == '#N/A'
  begin
    doi = row['doi'].sub('doi:', '')
    unless Item.exists?(doi: doi)
      item = Item.new(doi: doi, handle: row['scholaris handle'], status: 'pending') 
      item.save
      print '.'
    end
  rescue StandardError => e
    puts e.message
  end
end



binding.pry