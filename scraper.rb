require 'scraperwiki'
require 'mechanize'
require 'active_support/core_ext/hash/slice'

def mock!
  puts "[debug] Mocking out data because we are in development mode"
  require 'webmock'
  include WebMock::API
  WebMock.enable!
  stub_request(:get, 'http://www.abc.net.au/news/2017-04-20/australian-politician-property-ownership-details/8453782').
    to_return(status: 200, body: File.read('sample.html'), headers: {'Content-Type' => 'text/html'})
end

def primary_key
  'id'
end

def existing_record_ids
  return @cached if @cached
  @cached = ScraperWiki.select("#{primary_key} from data").map {|r| r[primary_key]}
rescue SqliteMagic::NoSuchTable
  []
end

def md5(string)
  @hash ||= Digest::MD5.new
  @hash.hexdigest(string)
end

def extract_column_names(table)
  table.search('th').map {|th| th.text.downcase.split(/\s+/).join('_')}
end

def extract_properties(table, columns)
  properties = table.search('tr')[1..-1].each_with_index.map {|row, row_index|
    attrs = Hash[row.search('td').each_with_index.map {|td, index|
      [ columns[index], td.text.strip ]
    }]
    attrs.merge({'index' => row_index})
  }
end

def add_property_type_if_available(property)
  matcher = /\s+\((?<property_type>\w+)\)/
  if match = property['property_location'].match(matcher)
    property['property_type'] = match[:property_type]
    property['property_location'].gsub!(matcher, '')
  else
    property['property_type'] = nil
  end
end

def add_id(property)
  property[primary_key] = md5(property.inspect)
end

def scrape_properties
  agent = Mechanize.new
  page = agent.get('http://www.abc.net.au/news/2017-04-20/australian-politician-property-ownership-details/8453782')
  table = page.search('table')
  columns = extract_column_names(table)
  properties = extract_properties(table, columns)
  properties.each {|property| add_property_type_if_available(property) }
  properties.each {|property| add_id(property) }
  properties.each {|property| property.delete('index') } # we nuke this as it's only used to build an id
end

def count_per_party(properties)
  properties.map {|d| d['party']}.uniq.map {|party| [ party, properties.select {|d| d['party'] == party}.size ] }
end

def main
  mock! if ENV['SCRAPER_ENV'] == 'dev'
  properties = scrape_properties
  new_properties = properties.select {|r| !existing_record_ids.include?(r[primary_key])}

  puts "[info] There are #{existing_record_ids.size} existing properties"
  puts "[info] There are #{new_properties.size} new properties"
  ScraperWiki.save_sqlite(['id'], new_properties)
end

main
