require 'zd-search/tokeniser'

describe ZDSearch::Tokeniser do
    describe 'Tokenising integers' do
        it 'just returns the integers' do
            tk = ZDSearch::Tokeniser.new
            tokens_1 = tk.tokens_for_value(312523)
            tokens_2 = tk.tokens_for_value(-9843)
            expect(tokens_1).to eql([312523])
            expect(tokens_2).to eql([-9843])
        end
    end

    describe 'Tokenising floats' do
        it 'just returns the floats' do
            tk = ZDSearch::Tokeniser.new
            tokens_1 = tk.tokens_for_value(312523.77)
            tokens_2 = tk.tokens_for_value(-9843.837283)
            expect(tokens_1).to eql([312523.77])
            expect(tokens_2).to eql([-9843.837283])
        end
    end

    describe 'Tokenising booleans' do
        it 'just returns the booleans' do
            tk = ZDSearch::Tokeniser.new
            tokens_1 = tk.tokens_for_value(true)
            tokens_2 = tk.tokens_for_value(false)
            expect(tokens_1).to eql([true])
            expect(tokens_2).to eql([false])
        end
    end

    describe 'Tokenising strings' do
        it 'splits on spaces' do
            tk = ZDSearch::Tokeniser.new
            tokens = tk.tokens_for_value("split me  on     spaces")
            expect(tokens).to eql(['split', 'me', 'on', 'spaces'])
        end

        it 'splits on tabs' do
            tk = ZDSearch::Tokeniser.new
            tokens = tk.tokens_for_value("split\tme\ton\t\t\ttabs")
            expect(tokens).to eql(['split', 'me', 'on', 'tabs'])
        end

        it 'ignores leading & trailing whitespace' do
            tk = ZDSearch::Tokeniser.new
            tokens = tk.tokens_for_value("    ignorethewhitespace     ")
            expect(tokens).to eql(['ignorethewhitespace'])
        end

        it 'makes everything lowercase' do
            tk = ZDSearch::Tokeniser.new
            tokens = tk.tokens_for_value("This STRING cOnTaIns SOMECAPS")
            expect(tokens).to eql(["this", "string", "contains", "somecaps"])
        end

        it 'tokenises the empty string to the empty string' do
            tk = ZDSearch::Tokeniser.new
            tokens = tk.tokens_for_value("")
            expect(tokens).to eql([""])
        end

        it 'strips almost all punctuation except for \'' do
            tk = ZDSearch::Tokeniser.new
            tokens = tk.tokens_for_value("This string has compound-words (and brackets) and ends with a full stop.")
            expect(tokens).to eql([
                'this', 'string', 'has', 'compound', 'words', 'and',
                'brackets','and','ends', 'with', 'a', 'full', 'stop'
            ])
        end

        it 'does not strip out punctuation fron contractions' do
            tk = ZDSearch::Tokeniser.new
            tokens = tk.tokens_for_value("The contraction shouldn't be split up.")
            expect(tokens).to eql(['the', 'contraction', "shouldn't", 'be', 'split', 'up'])
        end
    end

    describe 'Tokenising arrays' do
        it 'splits them into the consituent parts' do
            tk = ZDSearch::Tokeniser.new
            tokens = tk.tokens_for_value(["StRiNg value", 88.23, false])
            expect(tokens).to eql(["string", "value", 88.23, false])
        end

        it 'tokenises the empty array to the empty string' do
            tk = ZDSearch::Tokeniser.new
            tokens = tk.tokens_for_value([])
            expect(tokens).to eql([""])
        end
    end
end
