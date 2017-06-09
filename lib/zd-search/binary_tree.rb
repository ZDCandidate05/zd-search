# This is a pretty straightforward implementation of a fairly vanilla, generic
# binary search tree. It is used in the implementation of the BinaryTreeIndex
# search engine; see binary_tree_index.rb for details of its usage.

module ZDSearch
    class BinaryTree
        Node = Struct.new("Node", :key, :value, :left, :right)

        def initialize(root: nil)
            @root = root
        end

        def []=(key, value)
            set(key, value)
        end

        def [](key)
            # Quack like a ruby Hash - return nil if not found.
            is_found, value_or_nil = get_with_found(key)
            return value_or_nil
        end

        def include?(key)
            is_found, _ = get_with_found(key)
            return is_found
        end

        # Performs an inorder traversal of this tree
        # A block passed in will be called on each element with (key, value),
        # else an Enumerator object is returned.
        def inorder_traversal
            enum = Enumerator.new do |yielder|
                recursive_inorder_enum(current_node: @root, yielder: yielder)
            end

            if block_given?
                return enum.each { yield }
            else
                return enum
            end
        end

        # Create a _copy_ of this tree that is balanced. Implentation is a fairly
        # straightforward recursive constructuion of a new tree from a sorted array
        # of this one's elements.
        def balanced_copy
            return BinaryTree.new(root: create_balanced_copy_subtree(elements: inorder_traversal.to_a))
        end

        # Computes the height of this binary tree - the size of the longest path from
        # the root to any leaf 
        def height
            depths = []
            recursive_yield_leaf_heights(current_node: @root, depth: 0) { |depth| depths << depth }
            return depths.max || 0 # The depth of an empty tree is zero.
        end

        private

        def set(key, value)
            if @root.nil?
                @root = Node.new(key, value)
                return
            end

            # Else traverse down the branches looking for somewhere to put this key.
            current_node = @root
            loop do
                if current_node.key == key
                    # Found an exact match already in the tree
                    current_node.value = value
                    break
                elsif current_node.key > key && current_node.left.nil?
                    current_node.left = Node.new(key, value)
                    break
                elsif current_node.key < key && current_node.right.nil?
                    current_node.right = Node.new(key, value)
                    break
                elsif current_node.key > key
                    current_node = current_node.left # Keep searching
                elsif current_node.key < key
                    current_node = current_node.right
                else
                    raise "Unreachable else branch reached (???)"
                end
            end

            return nil
        end

        # Note: Returns a tuple of (found, nil?) so you can tell the difference between
        # a value of nil or the key not being present. Not suitable for a public interface.
        def get_with_found(key)
            current_node = @root
            while current_node && current_node.key != key
                if current_node.key > key
                    current_node = current_node.left
                elsif current_node.key < key
                    current_node = current_node.right
                end
            end

            if current_node.nil?
                return [false, nil]
            else
                return [true, current_node.value]
            end
        end

        def recursive_inorder_enum(current_node:, yielder:)
            return if current_node.nil?
            recursive_inorder_enum(current_node: current_node.left, yielder: yielder)
            yielder << [current_node.key, current_node.value]
            recursive_inorder_enum(current_node: current_node.right, yielder: yielder)
        end

        def recursive_yield_leaf_heights(current_node:, depth:, &blk)
            if current_node.nil?
                blk.call depth
            else
                recursive_yield_leaf_heights(current_node: current_node.left, depth: depth + 1, &blk)
                recursive_yield_leaf_heights(current_node: current_node.right, depth: depth + 1, &blk)
            end
        end

        # Note: elements: needs to be an array of [key, value] pairs like comes out of
        # #inorder_traversal
        def create_balanced_copy_subtree(elements:)
            return nil if elements.empty?


            centre_ix = (elements.size / 2).floor
            return Node.new(
                elements[centre_ix][0],
                elements[centre_ix][1],
                create_balanced_copy_subtree(elements: elements[0...(centre_ix)]),
                create_balanced_copy_subtree(elements: elements[(centre_ix+1)..-1]),
            )
        end
    end
end
