# Ruby implementation of our search index.
#
# The interface for the search indexes in this program is in two parts - first, a
# builder is used to collect all of the search tokens & relevant objects, and then
# the #build_index! method is called to obtain a data structure suitable for
# fast searching.
#
# This two-part interface lets us use a simple, non-self-balancing binary tree as
# an implementation, since it can be balanced exactly once after all data has been
# added and and has no need to support adding search tokens after creation. If mixed
# insertion & search operations became a requirement, this could be replaced with
# a self-balancing implementation (and the interface adjusted to suit).

require 'zd-search/binary_tree'

module ZDSearch
    class BinaryTreeSearchIndex
        # Represents an indexed hash/field pair, where a result might be found
        Match = Struct.new('Match', :hash, :field)

        class Builder
            def initialize(tokeniser:)
                # Store each type of data we understand in its own index. This is needed
                # because otherwise we'd need a comparison between each of these classes
                # in order to keep them in the binary tree correctly.
                @index_trees = {
                    :integer => ZDSearch::BinaryTree.new,
                    :float => ZDSearch::BinaryTree.new,
                    :string => ZDSearch::BinaryTree.new,
                    :boolean => ZDSearch::BinaryTree.new,
                }
                @tokeniser = tokeniser
            end

            # Indexes the given hash into the index we're building. Pulls out all the
            # fields, tokenises the values it finds, and stores them in the index.
            def index(hash)
                matches_by_token = {}
                hash.each do |field_name, value|
                    @tokeniser.tokens_for_value(value).each do |token|
                        matches_by_token[token] ||= []
                        matches_by_token[token] << Match.new(hash, field_name)
                    end
                end

                # Put the matches into the appropriate index depending on token type
                matches_by_token.each do |token, match_list|
                    index = @index_trees[ZDSearch::BinaryTreeSearchIndex._symbol_for_type(token.class)]
                    existing_matches = index[token] ||= []
                    # Mutates existing_matches in-place to avoid having to look it up
                    # in the tree again
                    existing_matches.concat match_list
                end
            end

            # Returns a BinaryTreeSearchIndex object, ready to answer search queries
            def build_index!
                balanced_trees = Hash[
                    @index_trees.map { |type, tree| [type, tree.balanced_copy] }
                ]
                return ZDSearch::BinaryTreeSearchIndex.new(sorted_index_trees: balanced_trees, tokeniser: @tokeniser)
            end
        end

        def initialize(sorted_index_trees:, tokeniser:)
            @sorted_index_trees = sorted_index_trees
            @tokeniser = tokeniser
        end

        # Returns a list of (object, field_name) pairs in our index for the specific token
        # Specify restrict_field to restrict returned matches to a particular field.
        def matches_for(search_term, restrict_field: nil)
            # Tokenise the search term, so that it will match the format of what we indexed
            search_term = @tokeniser.tokens_for_value(search_term).first
            return [] if search_term.nil?

            index = @sorted_index_trees[ZDSearch::BinaryTreeSearchIndex._symbol_for_type(search_term.class)]
            matches = index[search_term]
            return [] if matches.nil?

            # The #select call is important even in the restrict_field: nil
            # case because it prevents us from returning the matches list for mutation.
            return matches.select do |match|
                match.field == restrict_field || restrict_field.nil?
            end
        end

        # The only reason this stupid method is needed is because TrueClass and
        # FalseClass have no common ancestor in ruby, so we can't define a hash
        # mapping classes => index.
        def self._symbol_for_type(clazz)
            type_sym = if clazz <= Integer
                :integer
            elsif clazz <= Float
                :float
            elsif clazz <= String
                :string
            elsif clazz <= TrueClass || clazz <= FalseClass
                :boolean
            else
                raise TypeError.new("Don't support indexing #{clazz}")
            end
            return type_sym
        end
    end
end
