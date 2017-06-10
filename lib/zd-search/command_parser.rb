# This module helps out the CLI by interring semantic meaning from CLI commands.
# Extracting this logic out like this helps it be testable outside of the other
# parts of the CLI that do I/O.

require 'zd-search'

module ZDSearch
    module CommandParser
        SearchCommand = Struct.new('SearchCommand', :type, :field, :term)

        class SearchCommandError < StandardError
            def initialize(code)
                @code = code
            end
            attr_reader :code
        end

        # Parse the search command. Note that the command has already been split on whitespace
        # by the CLI. If the command is malformed in some way, then we throw a SearchCommandError
        # with a specific code (which can be used to present the correct error message)
        def self.parse_search_command(command_tokens)
            # Second token should be object_type:field_name
            object_field_pair = command_tokens[1]
            if object_field_pair.nil?
                raise SearchCommandError.new(:err_no_object_type)
            end

            object_type, field_name = command_tokens[1].split(':')
            raise SearchCommandError.new(:err_no_object_type) unless object_type
            raise SearchCommandError.new(:err_no_field_name) unless field_name

            if !ZDSearch::OBJECT_TYPES.include?(object_type)
                raise SearchCommandError.new(:err_invalid_object_type)
            end

            search_term = command_tokens[2]
            raise SearchCommandError.new(:err_no_search_term) if search_term.nil?
            if command_tokens.size > 3
                raise SearchCommandError.new(:err_extra_arguments)
            end

            # The search term might need to be coalesced into int/bool
            result = SearchCommand.new(object_type, field_name)
            if /^[0-9]+$/ =~ search_term
                result.term = search_term.to_i
            elsif /^[0-9]+\.[0-9]+$/ =~ search_term
                result.term = search_term.to_f
            elsif search_term.downcase == 'false'
                result.term = false
            elsif search_term.downcase == 'true'
                result.term = true
            else
                result.term = search_term
            end

            return result
        end
    end
end
