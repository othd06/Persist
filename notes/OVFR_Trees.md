
# Offset-Virtualised Fixed Radix Trees: A Simpler Alternative to RRB Trees

## Persistent Vectors:

"In developing immutable hash maps for Clojure, lead developer Rich Hickey used Hash Array Mapped Tries (HAMT) [1] as the basis. HAMT’s use a 32-way branching structure to implement a mutable hash map. The immutable version, pioneered by Clojure, was created understanding that only the tree path needed to be rewritten as items were added or removed from the map. The same 32 way branching structure was then used to provide an immutable vector. In this case the ‘key’ to an item is its index in the vector rather than a hash of the key. Again immutability was achieved by copying and updating only the tree path for updates and additions, with the 32-way branching leading to log_32(N) index performance."[Phil Bagwell & Tiark Rompf 2012]

For the purposes of this, we will be considering a variation of persistent vectors with a radix of 64 rather than 32.

## Offset-Virtualisation:

Note that in the case of persistent vectors the branch factor, or radix, _m_ is always 64. This constant _m_ is what allows the radix search to find the correct child just by index. This, however, results in several key operations such as:
  *  arbitrary deletion
  *  deletion from the start
  *  concatenation
  *  etc...

being expensive (>= O(n)) to perform.

To resolve this we can add Offset-Virtualisation. Offset-Virtualisation is the process of replacing elements of our fixed-radix tree with virtual elements that contribute to the structure but are skipped as part of the list.

To do this we require some additional bookkeeping on our nodes. For our leaf nodes, we add an offset value denoting that data in branches lower than said offset are to be ignored and treated as not present. We say radices lower than this offset store _virtual_ values in that they contribute to the structure of the tree but can be ignored in its concrete implementation and we call values that appear after the offset _true_ values. This, however, means that we can no longer calculate how many values are present in some subtree based solely on its height meaning we have to add a _length_ value to each node denoting the number of true values in that subtree and which operations must maintain correctly. We can then find the child subtree containing a particular index by iterating through each of the child nodes until the cumulative stored length value exceeds the index, allowing us to know that this child is the root of the correct subtree. This, however, complicates appending to the list encoded by such a tree since we cannot know from the number of elements present whether there is more room to append to this tree or if we must append to it's right sibling. To solve this, we also denote in each subtree whether that subtree has space to be appended to or not. The final component of offset-virtualisation is _dummy nodes_. If a subtree (including a single leaf node) contains only virtual values then we can use a dummy node which is a node of the correct nominal depth but with no children, a stored length of 0, and no room to grow. Notice that since dummy nodes do affect the number of virtual values, they affect the time complexity of certain operations to some degree however since they contain no children or data of their own they take up little to no memory. Furthermore, since dummy nodes have nominal tree heights corresponding to their virtual elements, it is helpful (though not necessary) to store the nominal depth of a node as part of it's bookkeeping data.

It should be noted that, much like a standard radix-searched persistent vector we grow left to right, bottom to top. That is to say that the depth of every leaf node relative to the root node is equal and that the index of true values is ordered from leftmost to rightmost. Therefore, unless the number of true and virtual values is a power of 64, there very likely exist potential nodes to the right of the end of the list being encoded by our tree. It is crucial that these be distinguishable from dummy nodes hence it is customary to use a null pointer for these potential nodes; a node with length 0 and nominal room to grow would also work however it takes up more memory to store values outside of the range we care about.

Note also, that it is perfectly legal to "defragment" an offset-virtualised fixed radix tree by rebuilding it to contain only true values in the same order in-place without violating persistence since the encoded list remains equivalent however doing so is likely only worthwhile once the number of virtual elements is large since doing so sacrifices structural sharing with other lists.

## Operations:

Offset Virtualisation is only as good as it allows operations to be faster so now it's time to consider some operations that are typically trickier and see how offset-virtualisation can assist.

Note, we will use _n_ to denote the number of true values contained in the list and _m_ to denote the number of true or virtual values contained in the list (note that calculating the true value of m within the range of the tree that is in bounds of the list is itself a fairly simple O(log_64(m)) operation)

### Dropping:

To drop one element, simply increase the offset of the leftmost child in O(log_64(m)) time

### Deletion:

To delete one element, we can find the leaf node corresponding to that element in O(log_64(m)) time and copy each prior value in that child node one branch forward then increase the offset of that leaf node accordingly in O(1) time, adjusting the bookkeeping values above as required in O(log_64(m)) time

### Concatenation:

If the RHS list is encoded by a tree of equal or lesser height, we can copy the values of the rightmost leaf of the LHS tree and adjust the offset and space tag accordingly upwards as well as adding whatever sibling and (great)* aunt/uncle dummy nodes are required to completely fill all the nodes of LHS up to the height of RHS at which point we simply make RHS a subtree of LHS.

If RHS is encoded by a tree of greater depth then we can pad LHS with dummy sibling and (great)* aunt/uncle nodes from the root to build our virtual tree upwards, marking that there is no room to grow where needed until it is the height of RHS at which point we can make LHS and RHS the first and second children of a new shared parent root node.
radix-searched persistent vector we grow left to right, bottom to top. That is to say that the depth of every leaf node relative to the root node is equal and that the index of true values is ordered from leftmost to rightmost. Therefore, unless the number of true and virtual values is a power of 64, there very likely exist potential nodes to the right of the end of the list being encoded by our tree. It is crucial that these be distinguishable from dummy nodes hence it is customary to use a null pointer for these potential nodes; a node with length 0 and nominal room to grow would also work however it takes up more memory to store values outside of the range we care about.
