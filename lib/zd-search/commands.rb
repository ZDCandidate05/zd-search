require 'zd-search'
require 'active_support/core_ext/hash'

module ZDSearch
    class SearchCommand
        class ParseError < StandardError
            def initialize(code)
                @code = code
            end
            attr_reader :code
        end

        # Creates the command object based on the tokens from the CLI command entered
        # Needs to be of the form ['search', 'object_type.field', 'term']
        # Raises a ParseError if the command text is invalid in some way.
        def initialize(command_tokens)
            # Second token should be object_type:field_name
            object_field_pair = command_tokens[1]
            if object_field_pair.nil?
                raise ParseError.new(:err_no_object_type)
            end

            @object_type, @field_name = command_tokens[1].split('.')
            raise ParseError.new(:err_no_object_type) unless @object_type
            raise ParseError.new(:err_no_field_name) unless @field_name

            if !ZDSearch::OBJECT_TYPES.include?(object_type)
                raise ParseError.new(:err_invalid_object_type)
            end

            search_term_str = command_tokens[2]
            raise ParseError.new(:err_no_search_term) if search_term_str.nil?
            if command_tokens.size > 3
                raise ParseError.new(:err_extra_arguments)
            end

            # The search term might need to be coalesced into int/bool
            if /^[0-9]+$/ =~ search_term_str
                @search_term = search_term_str.to_i
            elsif /^[0-9]+\.[0-9]+$/ =~ search_term_str
                @search_term = search_term_str.to_f
            elsif search_term_str.downcase == 'false'
                @search_term = false
            elsif search_term_str.downcase == 'true'
                @search_term = true
            else
                @search_term = search_term_str
            end
        end

        attr_reader :object_type, :field_name, :search_term

        # Actually execute the search against the provided index.
        # Returns a list of hashes for display, including related object references.
        def execute(index)
            matches = index.hashes_for @search_term, restrict_type: @object_type, restrict_field: @field_name
            return matches.map do |matched_object|
                # Polymorphism of some kind would probably be cleaner than this, but this is literally the
                # only part of the codebase that cares, so... ¯\_(ツ)_/¯
                case @object_type
                when 'organization'
                    ticket_matches = index.hashes_for matched_object['_id'], restrict_type: 'ticket', restrict_field: 'organization_id'
                    user_matches = index.hashes_for matched_object['_id'], restrict_type: 'user', restrict_field: 'organization_id'
                    next {
                        '_tickets' => ticket_matches.map { |t| t.slice('_id', 'subject')},
                        '_users' => user_matches.map { |t| t.slice('_id', 'name')},
                    }.merge(matched_object)
                when 'ticket'
                    asignee_matches = index.hashes_for matched_object['asignee_id'], restrict_type: 'user', restrict_field: '_id'
                    submitter_matches = index.hashes_for matched_object['submitter_id'], restrict_type: 'user', restrict_field: '_id'
                    organization_matches = index.hashes_for matched_object['organization_id'], restrict_type: 'organization', restrict_field: '_id'
                    next {
                        '_assignee' => asignee_matches.map { |t| t.slice('_id', 'name') },
                        '_submitter' => submitter_matches.map { |t| t.slice('_id', 'name') },
                        '_organization' => organization_matches.map { |t| t.slice('_id', 'name') },
                    }.merge(matched_object)
                when 'user'
                    asignee_matches = index.hashes_for matched_object['_id'], restrict_type: 'ticket', restrict_field: 'asignee_id'
                    submitter_matches = index.hashes_for matched_object['_id'], restrict_type: 'ticket', restrict_field: 'submitter_id'
                    organization_matches = index.hashes_for matched_object['organization_id'], restrict_type: 'organization', restrict_field: '_id'
                    next {
                        '_assigned_tickets' => asignee_matches.map { |t| t.slice('_id', 'subject') },
                        '_submitted_tickets' => submitter_matches.map { |t| t.slice('_id', 'subject') },
                        '_organization' => organization_matches.map { |t| t.slice('_id', 'name') },
                    }.merge(matched_object)

                end 
            end
        end
    end
end
