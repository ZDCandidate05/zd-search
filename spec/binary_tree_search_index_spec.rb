require 'zd-search/binary_tree_search_index'
require 'zd-search/tokeniser'

describe ZDSearch::BinaryTreeSearchIndex do
    before(:each) do
        @tokeniser = ZDSearch::Tokeniser.new
        @index_builder = ZDSearch::BinaryTreeSearchIndex::Builder.new(tokeniser: @tokeniser)
    end

    let(:o1) { {
        'oink' => 3,
        'bork' => 'Some super long and DESCRIPTIVE (& useful!) text',
        'quark' => 'Less borkey text',
        'is_quack' => true,
        'honk' => [ 'Other', 'Pieces' ],
        'eek' => 4,
        '_type' => 'eel',
    } }

    let(:o2) { {
        'oink' => 34,
        'bork' => 'LESS USEFUL but more interesting text.',
        'quark' => 'Definitely does not have the t-word.',
        'is_quack' => false,
        'honk' => [ 'Other', 'Pieces' ],
        'eek' => 1,
        '_type' => 'eel',
    } }

    let(:o3) { {
        'oink' => 34,
        'bork' => "definitely borks (and barks, can't it?) pretty hard and is useful.",
        'quark' => '',
        'is_quack' => true,
        'honk' => [ 'Other', 'Pieces' ],
        'eek' => 0,
        '_type' => 'salmon',
    } }

    describe 'string searches' do
        it 'returns exact string matches' do
            @index_builder.index(o1)
            ix = @index_builder.build_index!
            matches = ix.matches_for('long')
            expect(matches).to have(1).item
            expect(matches[0].hash).to eql(o1)
            expect(matches[0].field).to eql('bork')
        end

        it 'can return multiple matches' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            ix = @index_builder.build_index!
            matches = ix.matches_for('text')
            expect(matches).to have(3).items
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o1, 'bork'))
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o1, 'quark'))
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o2, 'bork'))
        end

        it 'returns no matches if none exist' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            ix = @index_builder.build_index!
            matches = ix.matches_for('hypothetical')
            expect(matches).to have(0).items
        end

        it 'appropriately tokenises the query to match the index' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            ix = @index_builder.build_index!
            matches = ix.matches_for('TeXT...')
            expect(matches).to have(3).items
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o1, 'bork'))
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o1, 'quark'))
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o2, 'bork'))
        end

        it 'returns objects with the field empty if searching the empty string' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            @index_builder.index(o3)
            ix = @index_builder.build_index!
            matches = ix.matches_for('')
            expect(matches).to have(1).item
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o3, 'quark'))
        end
    end

    describe 'integer matches' do
        it 'only returns exact integer matches' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            @index_builder.index(o3)
            ix = @index_builder.build_index!
            matches = ix.matches_for(34)
            expect(matches).to have(2).items
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o2, 'oink'))
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o3, 'oink'))
        end

        it 'returns no matches if none exist' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            @index_builder.index(o3)
            ix = @index_builder.build_index!
            matches = ix.matches_for(345)
            expect(matches).to have(0).items
        end
    end

    describe 'boolean matches' do
        it 'only returns exact boolean matches' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            @index_builder.index(o3)
            ix = @index_builder.build_index!
            matches = ix.matches_for(true, restrict_field: 'is_quack')
            expect(matches).to have(2).items
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o1, 'is_quack'))
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o3, 'is_quack'))
        end

        it 'returns no matches if none exist' do
            @index_builder.index(o1)
            @index_builder.index(o3)
            ix = @index_builder.build_index!
            matches = ix.matches_for(false, restrict_field: 'is_quack')
            expect(matches).to have(0).items
        end

        it 'does not accidently return integers' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            @index_builder.index(o3)
            ix = @index_builder.build_index!
            matches = ix.matches_for(false)
            expect(matches).to have(1).items
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o2, 'is_quack'))
            expect(matches).to_not include(ZDSearch::BinaryTreeSearchIndex::Match.new(o3, 'eek'))
        end
    end

    describe 'restrict_field' do
        it 'filters by field if restrict_field is provided' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            ix = @index_builder.build_index!
            matches = ix.matches_for('text', restrict_field: 'bork')
            expect(matches).to have(2).items
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o1, 'bork'))
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o2, 'bork'))
        end
    end

    describe 'restrict_type' do
        it 'filters by _type if restrict_typeis provided' do
            @index_builder.index(o1)
            @index_builder.index(o2)
            @index_builder.index(o3)
            ix = @index_builder.build_index!
            matches = ix.matches_for('useful', restrict_type: 'salmon')
            expect(matches).to have(1).items
            expect(matches).to include(ZDSearch::BinaryTreeSearchIndex::Match.new(o3, 'bork'))
        end
    end
end
