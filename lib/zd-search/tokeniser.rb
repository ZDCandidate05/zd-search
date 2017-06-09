# This class is responsible for extracting searchable tokens from a
# hash. It can deal with numeric, boolean, and string fields and, in the case
# of a string field, splits it on word boundaries and normalises them to
# lower case. This supports subsequent case-insensitive retrieval.

module ZDSearch
    class Tokeniser

        STRING_TOKENIZE_PATTERN = /\s/

        def tokens_for_value(value)
            # Numbers & booleans just tokenise to themselves
            if value.is_a?(Integer) || value.is_a?(Float) || value == true || value == false
                return [value]
            elsif value.is_a?(String)
                # If this were a real search app, we'd do things like stemming and ignoring
                # stopwords here. We don't need to support any of that however :)
                tokens = value.split(STRING_TOKENIZE_PATTERN)
                            .reject(&:empty?)
                            .map(&:downcase)
                # Special case - if there are no tokens from the string field, give it the "" token.
                # This is used to meet the requirement that we can find empty fields.
                tokens << "" if tokens.empty?
                return tokens
            elsif value.is_a?(Array)
                # Each element in an array is tokenised separately
                tokens = value.flat_map { |v| tokens_for_value(v) }
                # As above, index the empty state by tokenising it to ""
                tokens << "" if tokens.empty?
                return tokens
            else
                # Notable thing missing here: sub-hashes
                # None of the test input data appears to have them in the schema. If that changed, we could use something
                # like Elasticsearch's dotted-field notation to represent the sub-fields (i.e. "foo.bar.baz" would be its
                # own field)
                raise TypeError.new("Cannot tokenise #{value} because we do not support #{value.class} objects")
            end
        end
    end
end
