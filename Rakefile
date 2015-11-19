require 'dotenv/tasks'
require 'algoliasearch'
require 'csv'
require 'yaml'

task :init_config do
  @config = YAML.load_file('config.yml')
end

task :init_algolia => :dotenv do
  Algolia.init :application_id => ENV['ALGOLIA_APP_ID'],
               :api_key        => ENV['ALGOLIA_ADMIN_KEY']
  @index = Algolia::Index.new ENV['ALGOLIA_INDEX']
end

# Imports a CSV file to an Algolia index
# Usage: `rake import_csv[file.csv]`
task :import_csv, [:file] => [:init_config, :init_algolia] do |t, args|
  puts 'Initial import'
  puts "File: #{args.file}"

  # Read the file
  data = CSV.read(args.file)
  puts "#{data.length} lines read"

  keys = data.slice!(0)

  # Batch import, 500 at a time
  while data.length > 0
    if data.length > 500
      batch = data.slice! 0, 500
    else
      batch = data
    end

    batch.map! do |line|
      hash = Hash[keys.zip(line)]
      hash.select! do |key, value|
        @config['allowed_keys'].include? key
      end
      hash['objectID'] = hash['nationbuilder_id']
      hash.delete('nationbuilder_id')
      hash
    end

    res = @index.save_objects(batch)

    puts res.inspect
  end

end