require 'zd-search/binary_tree'

describe ::ZDSearch::BinaryTree do
    describe '#[] and #[]=' do
        it 'can get setted values' do
            bst = ZDSearch::BinaryTree.new
            bst[8] = :foo
            bst[1] = :quack
            bst[32] = ['Some', :other, 3]

            expect(bst[8]).to eql(:foo)
            expect(bst[1]).to eql(:quack)
            expect(bst[32]).to eql(['Some', :other, 3])
        end

        it 'works with jagged insertion order' do
            bst = ZDSearch::BinaryTree.new
            bst[8] = :foo
            bst[1] = :quack
            bst[32] = ['Some', :other, 3]
            bst[6] = :QUOCK
            bst[3] = :ik

            expect(bst[6]).to eql(:QUOCK)
            expect(bst[3]).to eql(:ik)
        end

        it 'returns nil when keys do not exit' do
            bst = ZDSearch::BinaryTree.new
            bst[8] = :foo
            bst[1] = :quack
            bst[32] = ['Some', :other, 3]

            expect(bst[77]).to eql(nil)
        end

        it 'works with string keys' do
            bst = ZDSearch::BinaryTree.new
            bst["eight"] = :foo
            bst["one"] = :quack
            bst["thirty-two"] = ['Some', :other, 3]

            expect(bst["eight"]).to eql(:foo)
            expect(bst["one"]).to eql(:quack)
            expect(bst["thirty-two"]).to eql(['Some', :other, 3])
        end
    end

    describe '#include?' do
        it 'positively works with jagged insertion order' do
            bst = ZDSearch::BinaryTree.new
            bst[8] = :foo
            bst[1] = :quack
            bst[32] = ['Some', :other, 3]
            bst[6] = :QUOCK
            bst[3] = :ik
            bst[9] = :I_WILL_NOT_FAIL

            expect(bst).to include(8)
            expect(bst).to include(1)
            expect(bst).to include(32)
            expect(bst).to include(6)
            expect(bst).to include(3)
            expect(bst).to include(9)
        end

        it 'returns false when the object is not in the tree' do
            bst = ZDSearch::BinaryTree.new
            bst[:in] = 'in the tree'

            expect(bst).to_not include(:out)
        end
    end

    describe '#inorder_traversal' do
        it 'returns keys ascending' do
            bst = ZDSearch::BinaryTree.new
            bst[8] = :foo
            bst[1] = :quack
            bst[32] = ['Some', :other, 3]
            bst[6] = :QUOCK
            bst[3] = :ik
            bst[9] = :I_WILL_NOT_FAIL

            arr_keys = bst.inorder_traversal.map { |k, v| k }

            expect(arr_keys).to eql([1, 3, 6, 8, 9, 32])
        end

        it 'sorts strings lexographically' do
            bst = ZDSearch::BinaryTree.new
            bst["aadvark"] = 1
            bst["zeebra"] = 2
            bst["zombie"] = 3
            bst["quack"] = 4

            arr_keys = bst.inorder_traversal.map { |k, v| k }
            expect(arr_keys).to eql(["aadvark",  "quack", "zeebra","zombie"])
        end

        it 'does not yield on an empty tree' do
            bst = ZDSearch::BinaryTree.new

            expect { |b|
                bst.inorder_traversal(&b)
            }.to_not yield_control
        end
    end

    describe '#balanced_copy and #height' do
        it 'works on a half balanced tree' do
            bst = ZDSearch::BinaryTree.new
            bst[8] = :foo
            bst[1] = :quack
            bst[32] = ['Some', :other, 3]
            bst[6] = :QUOCK
            bst[3] = :ik
            bst[9] = :I_WILL_NOT_FAIL

            expect(bst.height).to eql(4)
            expect(bst.balanced_copy.height).to eql(3)
        end

        it 'works on a pathalogically unbalanced tree' do
            bst = ZDSearch::BinaryTree.new
            bst[1] = 1
            bst[2] = 2
            bst[3] = 3
            bst[4] = 4
            bst[5] = 5
            bst[6] = 6
            bst[7] = 7
            bst[8] = 8

            expect(bst.height).to eql(8)
            expect(bst.balanced_copy.height).to eql(4)
        end
    end
end