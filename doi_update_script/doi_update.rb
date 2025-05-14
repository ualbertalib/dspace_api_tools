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
      url = URI("#{ENV['DATACITE_API_ENDPOINT']}/dois/#{CGI.escape(self.doi)}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Put.new(url)
      request["accept"] = 'application/vnd.api+json'
      request["content-type"] = 'application/json'
      request.basic_auth(ENV['DATACITE_USERNAME'], ENV['DATACITE_PASSWORD'])
      request.body = "{\"data\":{\"type\":\"dois\",\"attributes\":{\"url\":\"#{self.handle}\"}}}"

      response = http.request(request)
      if response.kind_of? Net::HTTPSuccess
        self.status = 'success'
      else
        self.status = 'fail'
      end
      self.response_message = response.body.force_encoding("UTF-8")
    rescue StandardError => e
      self.status = 'fail'
      begin
        self.error_message = e.message.force_encoding("UTF-8")
        self.response_message = response.body.force_encoding("UTF-8") if response
      rescue StandardError => e
      end
    ensure 
      self.save
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
      print 'o'
    else
      print 'x'
    end
  rescue StandardError => e
    puts e.message
  end
end



count = 0
Item.where(status: 'pending').find_each do |item|
  item.update_doi
  print '.'
  count+= 1
  puts "success: #{Item.where(status: 'success').count}, failures: #{Item.where(status: 'fail').count}, pending #{Item.where(status: 'pending').count}" if count % 500 == 0
end
