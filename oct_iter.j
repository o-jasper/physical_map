#
#  Copyright (C) 23-08-2012 Jasper den Ouden.
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

OctTreeIter(at::OctTree, downto_level::Integer) =
    OctTreeIter([at],Array(OctTree,0),int16(downto_level))
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

#Iterates upward, which is good for for instance a point.
type OctTreeIterUpward
  at::OctTree
end

start(iter::OctTreeIterUpward) = iter

function next(q::Union(OctTreeIter,OctTree), iter::OctTreeIterUpward)
  assert( iter.at.parent!=nothing, "BUG: seems like `done` failed.")
  iter.at = iter.at.parent
  return (iter.at, iter)
end

done(q::Union(OctTreeIter,OctTree), iter::OctTreeIterUpward) =
    iter.at.parent==nothing

#Iterates upward and at a spot.
type OctTreeIterThing
  upward_p::Bool
  stage::Int8
  upward::OctTreeIterUpward
  downward::OctTreeIter

  OctTreeIterThing(upward::OctTreeIterUpward, downward::OctTreeIter, 
                   upward_first::Bool) =
      new(upward_first,int8(0), upward,downward)
end

OctTreeIterThing{T}(at::OctTree, thing::T,
                    downto_level::Integer,upward_first::Bool) =
    OctTreeIterThing(down_to_level(at, x,y,z, down_to_level),
                     downto_level, upward_first)

OctTreeIterThing(at::OctTree,downto_level::Integer,upward_first::Bool) =
    OctTreeIterThing(OctIterUpward(at), OctTreeIter(at, downto_level),
                     upward_first)

start(iter::OctTreeIterThing) = iter
function next(q::Union(OctTreeIter,OctTree), iter::OctTreeIterThing)
  assert(iter.stage < 2)
  if iter.upward_p
    ret,upward = next(q,iter.upward)
    iter.upward = upward
    if done(q,iter.upward)
      iter.stage += 1
      iter.upward_p = false
    end 
    return (ret,iter)
  else
    ret,downward = next(q,iter.downward)
    iter.downward = downward
    if done(q,iter.downward)
      iter.stage += 1
      iter.upward_p = true
    end 
    return (ret,iter)
  end
end
done(q::Union(OctTreeIter,OctTree), iter::OctTreeIterThing) = (iter.stage==2)


#Functions that make these iterators:

#Iterate down to some level.(level-by-level)
iter_downto(at::OctTree, downto_level::Integer) = OctTreeIter(at)
#iterate whole, first goes up. (level-by-level)
iter_whole(of::OctTree, downto_level::Integer) = 
    iter_downto(up_to_top(of),downto_level)
iter_whole(of::OctTree) = 
    iter_downto(up_to_top(of),typemin(Int16))
#Iterate all the way down. (level-by-level)
iter_down(at::OctTree) = OctTreeIter(at)

#Iterate upward.(effectively at a point)
iter_up(at::OctTree) = OctTreeIterUpward(at)
#Iterate at a point. You can break the for-loop to get upto_level.
iter_point(at::OctTree, point::(Number,Number,Number),
              down_to_level::Integer) =
    iter_up(down_to_level(at, x,y,z, down_to_level))

iter_point(at::OctTree, x::Number,y::Number,z::Number) = 
    iter_point(at, x,y,z, typemin(Int16))

#Iterate a thing. Difference is that you won't necessarily hit bottom. 
iter_thing{T}(at::OctTree, thing::T, down_to_level::Integer,
              upward_first::Bool) = 
    OctTreeIterThing(at, thing, downto_level)

iter_thing{T}(at::OctTree, thing::T, down_to_level::Integer) =
    iter_thing(at, thing, downto_level,true)

iter_thing{T}(at::OctTree, thing::T) =
    iter_thing(at, thing, typemin(Int16))
#That subcase.
iter_thing(at::OctTree, pos::(Number,Number,Number),
           down_to_level::Integer, upward_first::Bool) =
    iter_point(at, pos,down_to_level)

#TODO iter_block