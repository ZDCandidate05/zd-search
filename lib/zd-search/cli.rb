require 'trollop'
require 'rubygems'
require 'json'
require 'readline'
require 'zd-search'
require 'zd-search/binary_tree_search_index'
require 'zd-search/tokeniser'
require 'zd-search/commands'

module ZDSearch
    class CLI

        DEFAULT_DATA_DIR = File.realpath(File.join(File.dirname(__FILE__), '../../data'))
        COMMANDS = %w(fields search exit help)
        INTERACTIVE_HELP = <<~EOS
            To discover what fields are available to query
                > fields {#{ZDSearch::OBJECT_TYPES.join("|")}}
            To query on a particular object type/field pair
                > search {#{ZDSearch::OBJECT_TYPES.join("|")}}.FIELD SEARCH_TERM
            To exit
                > exit
                or
                > ^D
            To see this help again
                > help
        EOS

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
            @search_index = search_index_builder.build_index!

            time_delta_in_ms = ((Time.now - t1).to_f * 1000).round  
            puts "Done (in #{time_delta_in_ms} ms)."

            puts
            puts "Now dropping to the search shell."
            STDOUT.write INTERACTIVE_HELP


            # According to the ruby readline docs, we need to save the terminal state & restore it on exit.
            # Ignore a failure - if your system does not have /bin/stty (Windows?), you'll just have to deal with
            # broken terminal state if you CTRL+C
            stty_current_state = `stty --save`.chomp rescue nil
            Readline.completion_proc = method(:completion)
            begin
                while line = Readline.readline("zd-search> ", true)
                    command_tokens = line.split(' ')
                    case command_tokens.first
                    when 'fields'
                        run_fields_command command_tokens
                    when 'search'
                        run_search_command command_tokens
                    when 'exit'
                        break # Bail out of readline while loop
                    when 'help'
                        STDOUT.write INTERACTIVE_HELP
                    when nil 
                        # Do nothing; you'll just get a new prompt.
                    else
                        puts "Unknown command #{command_tokens.first}. Try `help` for help."
                    end
                end
            rescue Interrupt
                # Interactive terminals tend to treat CTRL+C as "bin this line and start again"
                # whilst also terminating any in-progress operation
                puts "\n"
                retry
            ensure
                if stty_current_state
                    system 'stty', stty_current_state rescue nil
                end
            end
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

        # Returns suggestions for readline completion. There's a whole lot more we could do to make this
        # more ergonomic, but it's messy & ugly & not really nescessary. As it is, just complete the main
        # initial commands.
        def completion(prefix)
            return COMMANDS.grep(/^#{Regexp.escape(prefix)}/)
        end

        def run_search_command(tokenised_command)
            # Delegate to a SearchCommand object
            cmd = begin
                ZDSearch::SearchCommand.new(tokenised_command)
            rescue ZDSearch::SearchCommand::ParseError => e
                puts "Malformed command (try `help` for usage instructions)"
                return
            end
            results = cmd.execute(@search_index)

            printf "%-20s %s\n", "Field name", "Value"
            printf "-----------------------------\n"
            results.each do |row|
                row.keys.sort.each do |field_name|
                    printf "%-20s %s\n", field_name, JSON.dump(row[field_name])
                end
                printf "-----------------------------\n"
            end
            puts "(found #{results.size} result(s))"
        end

        def run_fields_command(tokenised_command)
            cmd = begin
                ZDSearch::FieldsCommand.new(tokenised_command)
            rescue ZDSearch::FieldsCommand::ParseError => e
                puts "Malformed command (try `help` for usage instructions)"
                return
            end
            results = cmd.execute(@search_index)


            # Print out the known field values in 3 columns
            results.each_slice(3) do |fields|
                printf "%-40s %-20s %s\n", fields[0] || "", fields[1] || "", fields[2] || ""
            end
        end
    end
end
