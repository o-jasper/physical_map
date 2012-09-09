#
#  Copyright (C) 09-09-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#Allows the content to have lists, and the user to add stuff to the list
# using the octtree as spatial sort.

natural_level(size::Number) = int16(log2(size))

size_under(obj::(Number,Number,Number)) = 0
function size_under(block::Block) 
  fx,fy, tx,ty = block
  return min(tx-fx, ty-fy)
end
#Natural level of an object.
natural_level{O}(obj::O) = int16(log2(size_under(obj)))

#Define octtree_pos as x,y,z so that the object is at > that those.
octtree_pos(of::(Number,Number,Number) = of
octtree_pos(block::Block) =block[1]

#Adding objects.
function add_obj{O,M}(to::OctTree, obj::O, natural_level::Int16, manner::M)
  pos = octtree_pos(obj)
  add_to = to_level(to, pos, natural_level) #Find where to put it.
  #Put it there.
  if add_obj(add_to, obj,m) #User has to define add_obj, should return if it needs deepening.
    deepen_1_whole(add_to)
    after_deepen(add_to,m) #Another user-defined thing.
  end
end
#Default: figure level from obj.
add_obj{O}(to::OctTree, obj::O, manner::M) = #!
    add_obj(to,obj, natural_level(obj),m)

#Iterating/searching for objects.
type SearchBlock
  level::Int16
  f::(Float64,Float64)
  cf::(Float64,Float64)
  t::(Float64,Float64)

  function SearchBlock(block::Block)
    f,t = block
    fx,fy = f
    tx,ty = t
    f = (float64(fx),float64(fy))
    return new(typemax(Int16), f,f (float64(tx),float64(ty)))
  end
end
#This is all that should make the search block work as we want.
function is_contained(in::OctTree, search::SearchBlock)
  if in.level != search.level
    in.level = search.level
    fx,fy = search.f
    add_size = 2.0^level
    cf = (fx - add_size, fy - add_size)
  end
  return is_contained(in, (cf, search.t))
end

#Returns iterator to search the block.
# The user has to access the lists himself.
iter_blocksearch(search::Block, in::OctTree) =
    iter_down(SearchBlock(search), in)
