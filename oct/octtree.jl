
module OctTreeModule

import Base.*, OJasper_Util.*

export OctTree, children_cnt, node_size

export iter_downto, iter_down, iter_whole
export add_obj, iter_blocksearch

export is_contained

#Stuff user can define about objects position for object, 
# preffered 'drop direction', either give the natural direction or indicate the size.
#(to define import it specifically!)
export octtree_pos,octtree_dirs, natural_level, size_under
#Defined about the content of the octree, how to add an object.
#(to define import it specifically!)
export enter_obj

export expand_to_level

export deepen_1_whole #TODO do i want this exported?..

export consistency_check_this, consistency_check_down, consistency_check

load("universe_map/oct/tree.jl")
load("universe_map/oct/expand.jl")
load("universe_map/oct/iter.jl")
load("universe_map/oct/things.jl")
load("universe_map/oct/list.jl")

end
