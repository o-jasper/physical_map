#
#  Copyright (C) 22-08-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#TODO what about iterators anyway? did they suck, why?

#Iterates down to some level.
type OctTreeIter
  list::Array{OctTree,1}
  next_list::Array{OctTree,1}
  downto_level::Int16
end

OctTreeIter(at::OctTree) =
    OctTreeIter([at],Array(OctTree,0),typemin(Int16))

start(at::OctTree) = OctTreeIter(at)
start(iter::OctTreeIter) = iter

function next(q::Union(OctTreeIter,OctTree), iter::OctTreeIter)
  function append_children(node)
    if node.level > iter.downto_level
      for el in ret.arr #Add the elements to make the next list.
        if el!=nothing 
          push(iter.next_list, el)
        end
      end
    end
  end
  if !isempty(iter.list) #Busy with current level.
    ret = pop(iter.list) #Pop it off.
    append_children(ret)
    return (ret,iter) #Return the given and continue.
  end
  assert(!isempty(iter.next_list), "Seems like `done` didn't work well.
(BUG if this was used via `for`)")
  #Go to the next list.
  iter.list = iter.next_list
  ret = pop(iter.list) #Start making the children for the first.
  iter.next_list = Array(OctTree,0)
  append_children(ret)
  return (ret,iter)
end

done(q::Union(OctTreeIter,OctTree),iter::OctTreeIter) = 
    isempty(iter.list) && isempty(iter.next_list)

type OctTreeIterAt

#Searches a block in space.
function iter_block(in::QuadTree,
                    from::(Number,Number,Number), to::(Number,Number,Number))
  
end