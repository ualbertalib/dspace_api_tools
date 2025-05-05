require 'csv'
require 'uri'
require 'net/http'
require 'cgi'

CSV.foreach("tmp/scholaris_items.csv", headers: true) do |row|
  return unless row['metadata.dc.identifier.doi']
  doi = row['metadata.dc.identifier.doi'].sub("https://doi.org/", "")
  url = URI("https://api.test.datacite.org/dois/#{CGI.escape(doi)}")

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Put.new(url)
  request["accept"] = 'application/vnd.api+json'
  request["content-type"] = 'application/json'
  request.basic_auth(ENV['DATACITE_USERNAME'], ENV['DATACITE_PASSWORD'])
  request.body = "{\"data\":{\"type\":\"dois\",\"attributes\":{\"url\":\"https://ualberta-dev.scholaris.ca/handle/#{row['handle']}\"}}}"

  puts request.to_hash
  puts request.body
  #response = http.request(request)
  #puts response.read_body
end
