#
#  Copyright (C) 23-08-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#TODO what about iterators anyway? did they suck, why?

type OctTreeWhole
end
is_contained(in::OctTree, whole::OctTreeWhole) = true

#Iterates down to some level.
type OctTreeIter{T}
  thing::T
  list::Array{OctTree,1}
  next_list::Array{OctTree,1}
  downto_level::Int16
end

OctTreeIter{T}(thing::T, at::OctTree, downto_level::Integer) =
    OctTreeIter(thing, [at],Array(OctTree,0),int16(downto_level))
OctTreeIter{T}(thing::T, at::OctTree) =
    OctTreeIter(thing, [at],Array(OctTree,0),typemin(Int16))

OctTreeIter{T}(thing::T, at::OctTree) =
    OctTreeIter(thing, [at],Array(OctTree,0),typemin(Int16))

OctTreeIter(at::OctTree, downto_level::Integer) =
    OctTreeIter(OctTreeWhole(), [at],Array(OctTree,0),int16(downto_level))
OctTreeIter(at::OctTree) =
    OctTreeIter(OctTreeWhole(), [at],Array(OctTree,0),typemin(Int16))

OctTreeIter(at::OctTree) =
    OctTreeIter(OctTreeWhole(), [at],Array(OctTree,0),typemin(Int16))

start(at::OctTree) = OctTreeIter(at)
start(iter::OctTreeIter) = iter

function next{T}(q::Union(OctTreeIter{T},OctTree), iter::OctTreeIter{T})
  function append_children(node)
    if node.level > iter.downto_level
      for el in ret.arr #Add the elements to make the next list.
        if el!=nothing && is_contained(el, iter.thing)
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

done{T}(q::Union(OctTreeIter{T},OctTree),iter::OctTreeIter{T}) = 
    isempty(iter.list) && isempty(iter.next_list)

#Iterates downward at a point. (NOTE: defaultly doesn't go up.)
type OctTreeIterPoint
  at::OctTree
  pos::(Float64,Float64,Float64)
  
  function OctTreeIterPoint(at::OctTree, pos::(Number,Number,Number))
    x,y,z = pos
    new(is_contained(at, pos) ? at : OctTree(), #dead end if not contained.
        (float64(x), float64(y), float64(z)))
  end
end
#Setting to top true makes it go all the way to the top.
OctTreeIterPoint(at::OctTree, pos::(Number,Number,Number), to_top::Bool) =
    OctTreeIterPoint(to_top ? up_to_top(at) : at, pos)
#Up to some level.
OctTreeIterPoint(at::OctTree, pos::(Number,Number,Number), 
                 to_level::Integer) =
    OctTreeIterPoint(up_to_level(at,to_level), pos)

start(iter::OctTreeIterPoint) = iter

function next(q::Union(OctTreeIter,OctTree), iter::OctTreeIterPoint)
  ret = iter.at
  iter.at = node_of_pos(iter.at, iter.pos)
  return (ret, iter)
end

done(q::Union(OctTreeIterPoint,OctTree), iter::OctTreeIterPoint) = 
    node_of_pos(iter.at,iter.pos) == nothing

#Iterates upward.
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