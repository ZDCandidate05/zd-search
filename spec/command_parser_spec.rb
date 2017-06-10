require 'zd-search/command_parser'

describe ZDSearch::CommandParser do
    describe '::parse_search_command' do
        it 'rejects if no object type specified' do
            expect {
                ZDSearch::CommandParser.parse_search_command(['search'])
            }.to raise_error(ZDSearch::CommandParser::SearchCommandError)
        end

        it 'rejects if no field name is specified' do
            expect {
                ZDSearch::CommandParser.parse_search_command(['search', 'organisation'])
            }.to raise_error(ZDSearch::CommandParser::SearchCommandError)
        end

        it 'rejects if no field name is specified, with a colon' do
            expect {
                ZDSearch::CommandParser.parse_search_command(['search', 'organisation:'])
            }.to raise_error(ZDSearch::CommandParser::SearchCommandError)
        end

        it 'rejects if no search term is specified' do
            expect {
                ZDSearch::CommandParser.parse_search_command(['search', 'organisation:_id'])
            }.to raise_error(ZDSearch::CommandParser::SearchCommandError)
        end

        it 'rejects if bonus content is supplied at the end' do
            expect {
                ZDSearch::CommandParser.parse_search_command(['search', 'user:name', 'bob', 'JUNK'])
            }.to raise_error(ZDSearch::CommandParser::SearchCommandError)
        end

        it 'rejects if the type is unknown' do
            expect {
                ZDSearch::CommandParser.parse_search_command(['search', 'hooser:name', 'bob'])
            }.to raise_error(ZDSearch::CommandParser::SearchCommandError)
        end

        it 'succeeds & returns the string if a normal string is given' do
            search = ZDSearch::CommandParser.parse_search_command(['search', 'user:name', 'bob'])
            expect(search.type).to eql('user')
            expect(search.field).to eql('name')
            expect(search.term).to eql('bob')
        end

        it 'coalesces int-looking things into ints' do
            search = ZDSearch::CommandParser.parse_search_command(['search', 'user:number', '88'])
            expect(search.type).to eql('user')
            expect(search.field).to eql('number')
            expect(search.term).to eql(88)
        end

        it 'coalesces double-looking things into doubles' do
            search = ZDSearch::CommandParser.parse_search_command(['search', 'user:number', '88.0'])
            expect(search.type).to eql('user')
            expect(search.field).to eql('number')
            expect(search.term).to eql(88.0)
        end

        it 'coalesces true into boolean' do
            search = ZDSearch::CommandParser.parse_search_command(['search', 'user:bool', 'true'])
            expect(search.type).to eql('user')
            expect(search.field).to eql('bool')
            expect(search.term).to eql(true)
        end

        it 'coalesces false into boolean' do
            search = ZDSearch::CommandParser.parse_search_command(['search', 'user:bool', 'false'])
            expect(search.type).to eql('user')
            expect(search.field).to eql('bool')
            expect(search.term).to eql(false)
        end
    end
end
