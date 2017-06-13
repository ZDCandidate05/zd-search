require 'zd-search/command_parser'
require 'zd-search/commands'

describe 'Commands' do
    describe ZDSearch::SearchCommand do
        describe '#initialize' do
            it 'rejects if no object type specified' do
                expect {
                    ZDSearch::SearchCommand.new(['search'])
                }.to raise_error(ZDSearch::SearchCommand::ParseError)
            end

            it 'rejects if no field name is specified' do
                expect {
                    ZDSearch::SearchCommand.new(['search', 'organisation'])
                }.to raise_error(ZDSearch::SearchCommand::ParseError)
            end

            it 'rejects if no field name is specified, with a colon' do
                expect {
                    ZDSearch::SearchCommand.new(['search', 'organisation.'])
                }.to raise_error(ZDSearch::SearchCommand::ParseError)
            end

            it 'rejects if no search term is specified' do
                expect {
                    ZDSearch::SearchCommand.new(['search', 'organisation._id'])
                }.to raise_error(ZDSearch::SearchCommand::ParseError)
            end

            it 'rejects if bonus content is supplied at the end' do
                expect {
                    ZDSearch::SearchCommand.new(['search', 'user.name', 'bob', 'JUNK'])
                }.to raise_error(ZDSearch::SearchCommand::ParseError)
            end

            it 'rejects if the type is unknown' do
                expect {
                    ZDSearch::SearchCommand.new(['search', 'hooser.name', 'bob'])
                }.to raise_error(ZDSearch::SearchCommand::ParseError)
            end

            it 'succeeds & returns the string if a normal string is given' do
                search = ZDSearch::SearchCommand.new(['search', 'user.name', 'bob'])
                expect(search.object_type).to eql('user')
                expect(search.field_name).to eql('name')
                expect(search.search_term).to eql('bob')
            end

            it 'coalesces int-looking things into ints' do
                search = ZDSearch::SearchCommand.new(['search', 'user.number', '88'])
                expect(search.object_type).to eql('user')
                expect(search.field_name).to eql('number')
                expect(search.search_term).to eql(88)
            end

            it 'coalesces double-looking things into doubles' do
                search = ZDSearch::SearchCommand.new(['search', 'user.number', '88.0'])
                expect(search.object_type).to eql('user')
                expect(search.field_name).to eql('number')
                expect(search.search_term).to eql(88.0)
            end

            it 'coalesces true into boolean' do
                search = ZDSearch::SearchCommand.new(['search', 'user.bool', 'true'])
                expect(search.object_type).to eql('user')
                expect(search.field_name).to eql('bool')
                expect(search.search_term).to eql(true)
            end

            it 'coalesces false into boolean' do
                search = ZDSearch::SearchCommand.new(['search', 'user.bool', 'false'])
                expect(search.object_type).to eql('user')
                expect(search.field_name).to eql('bool')
                expect(search.search_term).to eql(false)
            end
        end

        describe '#execute' do
            before(:each) do
                @tokeniser = ZDSearch::Tokeniser.new
                index_builder = ZDSearch::BinaryTreeSearchIndex::Builder.new(tokeniser: @tokeniser)
                index_builder.index({
                    '_type' => 'organization',
                    'url' => 'http://foo.bar/1',
                    '_id' => 1,
                    'name' => 'Organisation no1',
                })
                index_builder.index({
                    '_type' => 'organization',
                    'url' => 'http://foo.bar/2',
                    '_id' => 2,
                    'name' => 'Organisation no2',
                })
                index_builder.index({
                    '_type' => 'user',
                    'name' => 'First Person',
                    '_id' => 1,
                    'organization_id' => 1,
                })
                index_builder.index({
                    '_type' => 'user',
                    'name' => 'Second Person',
                    '_id' => 2,
                    'organization_id' => 1,
                })
                index_builder.index({
                    '_type' => 'user',
                    'name' => 'Third Person',
                    '_id' => 3,
                    'organization_id' => 2,
                })
                index_builder.index({
                    '_type' => 'user',
                    'name' => 'Org no1Agent',
                    '_id' => 4,
                    'organization_id' => 1,
                })
                index_builder.index({
                    '_type' => 'user',
                    'name' => 'Org no2Agent',
                    '_id' => 5,
                    'organization_id' => 2,
                })
                index_builder.index({
                    '_type' => 'ticket',
                    'subject' => 'HALP ME',
                    '_id' => 'three',
                    'organization_id' => 1,
                    'submitter_id' => 1,
                    'asignee_id' => 4,
                })
                index_builder.index({
                    '_type' => 'ticket',
                    'subject' => 'Plz halp',
                    '_id' => 'one',
                    'organization_id' => 1,
                    'submitter_id' => 1,
                    'asignee_id' => 4,
                })
                index_builder.index({
                    '_type' => 'ticket',
                    'subject' => 'it is broken',
                    '_id' => 'two',
                    'organization_id' => 2,
                    'submitter_id' => 3,
                    'asignee_id' => 5,
                })
                @index = index_builder.build_index!
            end

            describe 'searching for an organisation' do
                let(:matches) {
                    ZDSearch::SearchCommand.new(['search', 'organization.name', 'no1']).execute(@index)
                }

                it 'returns the matching results' do
                    expect(matches).to have(1).item
                    expect(matches[0]['_id']).to eql(1)
                end

                it 'returns the related tickets' do
                    expect(matches[0]['_tickets'].map { |t| t['_id']}).to match(['three', 'one'])
                end

                it 'returns the related users' do
                    expect(matches[0]['_users'].map { |u| u['_id']}).to match([1, 2, 4])
                end
            end

            describe 'searching for a user' do
                let(:matches) {
                    ZDSearch::SearchCommand.new(['search', 'user.name', 'first']).execute(@index)
                }

                it 'returns the matching results' do
                    expect(matches).to have(1).item
                    expect(matches[0]['_id']).to eql(1)
                end
                context 'the user is an asignee' do
                    let(:matches) {
                        ZDSearch::SearchCommand.new(['search', 'user.name', 'no2Agent']).execute(@index)
                    }
                    it 'returns related tickets where the user is an assignee' do
                        expect(matches[0]['_assigned_tickets']).to have(1).items
                        expect(matches[0]['_assigned_tickets'].map { |t| t['_id']}).to match(['two'])
                    end
                end
                context 'the user is a submitter' do
                    it 'returns related tickets where the user is a submitter' do
                        expect(matches[0]['_submitted_tickets']).to have(2).items
                        expect(matches[0]['_submitted_tickets'].map { |t| t['_id']}).to eql(['three', 'one'])
                    end
                end
                it 'returns the related organisation for the user' do
                    expect(matches[0]['_organization']).to have(1).item
                    expect(matches[0]['_organization'][0]['_id']).to eql(1)
                end
            end

            describe 'searching for a ticket' do
                let(:matches) {
                    ZDSearch::SearchCommand.new(['search', 'ticket.subject', 'broken']).execute(@index)
                }

                it 'returns the matching results' do
                    expect(matches).to have(1).item
                    expect(matches[0]['_id']).to eql('two')
                end

                it 'returns the related organisation for the user' do
                    expect(matches[0]['_organization'][0]['_id']).to eql(2)
                end
                it 'returns the related user that is an assignee' do
                    expect(matches[0]['_assignee'][0]['_id']).to eql(5)
                end
                it 'returns the related user that is a submitter' do
                    expect(matches[0]['_submitter'][0]['_id']).to eql(3)
                end
            end
        end
    end

    describe ZDSearch::FieldsCommand do
        it 'rejects if no object type is specified' do
            expect {
                ZDSearch::FieldsCommand.new(['fields'])
            }.to raise_error(ZDSearch::FieldsCommand::ParseError)
        end

        it 'rejects if the type is not valid' do
            expect {
                ZDSearch::FieldsCommand.new(['fields', 'some_random_type'])
            }.to raise_error(ZDSearch::FieldsCommand::ParseError)
        end

        it 'rejects if there are extra arguments' do
            expect {
                ZDSearch::FieldsCommand.new(['fields', 'ticket', 'foobar'])
            }.to raise_error(ZDSearch::FieldsCommand::ParseError)
        end

        it 'succeeds on valid types' do
            command = ZDSearch::FieldsCommand.new(['fields', 'ticket'])
            expect(command.object_type).to eql('ticket')
        end
    end
end
