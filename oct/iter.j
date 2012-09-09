#
#  Copyright (C) 09-09-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#TODO what about iterators anyway? did they suck, why?

type WholeOctTree
end
is_contained(in::OctTree, whole::WholeOctTree) = true

#Iterates down to some level.
type OctTreeIter{T}
  thing::T
  list::Array{OctTree,1}
  next_list::Array{OctTree,1}
  downto_level::Int16
end
#NOTE constructors aren't named as ones (object is not for direct use)

start(at::OctTree) = OctTreeIter(at)
start{T}(iter::OctTreeIter{T}) = iter

function next{T}(q::Union(OctTreeIter{T},OctTree), iter::OctTreeIter{T})
  function append_children(node)
    if node.level > iter.downto_level
      if is(node.arr, nothing)
        return 
      end
      for el in ret.arr #Add the elements to make the next list.
        if is_contained(el, iter.thing)
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
type OctTreeIterDown{T}
  at::Union(OctTree,Nothing)
  thing::T
  
  function OctTreeIterDown(at::OctTree, thing::T)
    new(is_contained(at, thing) ? at : OctTree(), #dead end if not contained.
        thing)
  end
end
#Setting to top true makes it go all the way to the top.
OctTreeIterDown{T}(at::OctTree, thing::T, to_top::Bool) =
    OctTreeIterDown(to_top ? up_to_top(at) : at, thing)
#Up to some level.
OctTreeIterDown{T}(at::OctTree, thing::T, to_level::Integer) =
    OctTreeIterDown(up_to_level(at,to_level), pos)

start{T}(iter::OctTreeIterDown{T}) = iter

function next{T}(q::Union(OctTreeIterDown{T},OctTree), 
                 iter::OctTreeIterDown{T})
  ret = iter.at
  iter.at = node_of_pos(iter.at, iter.thing)
  return (ret, iter)
end

done{T}(q::Union(OctTreeIterDown,OctTree), iter::OctTreeIterDown{T}) = 
    iter.at == nothing

#Iterates upward.(pretty useless afaik)
type OctTreeIterUpward
  at::Union(OctTree,Nothing)
end

start(iter::OctTreeIterUpward) = iter

function next(q::Union(OctTreeIter,OctTree), iter::OctTreeIterUpward)
  ret = iter.at
  iter.at = iter.at.parent
  return (ret, iter)
end

done(q::Union(OctTreeIter,OctTree), iter::OctTreeIterUpward) =
    iter.at==nothing

#Functions that make these iterators:

#'Bases' that actually construct the iterator.
iter_downto{T}(thing::T, at::OctTree, downto_level::Integer) =
    OctTreeIter(thing, [at],Array(OctTree,0),int16(downto_level))

#Note no point in downto level if you're iterating a point, just break.
iter_downto(pos::(Number,Number,Number), at::OctTree) = 
    OctTreeIterDown(at, pos)

#Various overloads.
iter_downto(at::OctTree, downto_level::Integer) =
    iter_downto(WholeOctTree(), at,downto_level)

iter_down{T}(thing::T, at::OctTree) =
    iter_downto(thing, at, typemin(Int16))
iter_down(at::OctTree) =
    iter_down(WholeOctTree(), at)

#iterate whole, first goes up. (level-by-level)
iter_whole{T}(thing::T, of::OctTree, downto_level::Integer) = 
    iter_downto(thing, up_to_top(of),downto_level)
iter_whole{T}(thing::T, of::OctTree) = 
    iter_down(thing, up_to_top(of))

iter_whole(of::OctTree, downto_level::Integer) = 
    iter_whole(WholeOctTree(), of, downto_level)
iter_whole(of::OctTree) = 
    iter_whole(WholeOctTree(), of)

