require 'trollop'
require 'rubygems'
require 'json'
require 'zd-search/binary_tree_search_index'
require 'zd-search/tokeniser'

module ZDSearch
    class CLI

        DEFAULT_DATA_DIR = File.realpath(File.join(File.dirname(__FILE__), '../../data'))

        def initialize
            self_spec = Gem::Specification.load('zd-search.gemspec')
            @opts = Trollop::options do
                version "zd-search #{self_spec.version} - KJ Tsanaktsidis"
                banner <<~EOS
                    zd-search #{self_spec.version} - KJ Tsanaktsidis

                    zd-search queries static JSON snapshots of Zendesk API data. Data directories are scanned
                    on startup and an index is precomputed. The interactive search shell then queries this
                    indexed data.

                    Usage:
                        [bundle exec] zd-search [options]
                EOS
                opt :organization_data, "Path to organization API output",
                    :type => :strings, :default => [File.join(DEFAULT_DATA_DIR, 'organizations.json')]
                opt :ticket_data, "Path to ticket API output",
                    :type => :strings, :default => [File.join(DEFAULT_DATA_DIR, 'tickets.json')]
                opt :user_data, "Path to user API output",
                    :type => :strings, :default => [File.join(DEFAULT_DATA_DIR, 'users.json')]
            end
        end

        def run!
            puts "Using organization data from #{@opts[:organization_data]}"
            puts "Using ticket data from #{@opts[:ticket_data]}"
            puts "Using user data from #{@opts[:user_data]}"
            puts

            t1 = Time.now
            puts "Loading data..."
            zendesk_data = load_objects

            puts "Indexing data..."
            search_index_builder = index_objects(zendesk_data)

            puts "Optimising index..."
            search_index = search_index_builder.build_index!

            time_delta_in_ms = ((Time.now - t1).to_f * 1000).round  
            puts "Done (in #{time_delta_in_ms} ms)."
        end

        # This method opens up the files specified on the command line and parses them.
        # As an added bonus, it tacks on a _type property, which can be later used to
        # identify what kind of hash this is.
        def load_objects
            objects = []
            [@opts[:organization_data], @opts[:ticket_data], @opts[:user_data]]
                .zip(['organization', 'ticket', 'user'])
                .map do |file_paths, object_type|
                    file_paths.each do |file_path|
                        read_objects = JSON.parse File.read(file_path)
                        read_objects.each { |o| o['_type'] = object_type }
                        objects.concat read_objects
                    end
                end
            return objects
        end

        def index_objects(zendesk_data)
            tokeniser = ZDSearch::Tokeniser.new
            index_builder = ZDSearch::BinaryTreeSearchIndex::Builder.new(tokeniser: tokeniser)
            zendesk_data.each do |object|
                index_builder.index(object)
            end
            return index_builder
        end
    end
end
