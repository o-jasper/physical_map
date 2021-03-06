#
#  Copyright (C) 09-09-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#Note 2.0^.. not being integer sidesteps changes there.

#TODO hrmm, arbitrary-size array (for instance 3*3*3)?
type OctTree
  parent::Union(Nothing,OctTree)
  level::Int16 #Depth, size of current block is 2*2^(+level)
  pos::(Float64,Float64,Float64)
  
  arr::Union(Nothing, Array{OctTree,1})
  
  content::Any

  function OctTree(parent,level::Integer, pos::(Number,Number,Number))
    x,y,z = pos
    return new(parent,int16(level), (float64(x),float64(y),float64(z)),
               nothing, nothing)
  end
end

enter_obj(to::OctTree, thing, manner) = 
    error("No method for entering object type $(typeof(thing)) 
in manner $manner")

children_cnt(o::OctTree) = (o.arr==nothing ? 0 : 8)

function show(o::OctTree)
  print("<OctTree level $(o.level), pos $(o.pos)")
  if o.parent!=nothing
    print(" has parent")
  end
  println(" children_cnt $(children_cnt(o))>")
end

OctTree(parent::OctTree, pos::(Number,Number,Number)) =
    OctTree(parent, parent.level-1, pos)
OctTree(level::Integer, pos::(Number,Number,Number)) =
    OctTree(nothing, level, pos)
OctTree(level::Integer) = OctTree(level, (0,0,0))
OctTree() = OctTree(0)

#NOTE much better algorithm involving multiple levels on one structure and
# jumping straight to a node on them,,, Avoiding mission creep, i guess.

#These three things enables the {T} stuff here to work.
#The one for the point is right here.

#Gets the index of the array where the subnodes live
index_of_pos{T}(from::OctTree, thing::T) = index_of_pos(from, octtree_pos(thing))

function index_of_pos(from::OctTree, pos::(Number,Number,Number))
  x,y,z = pos
  f_x,f_y,f_z = from.pos
  return 1+(x>f_x ? 1 : 0) + (y>f_y ? 2 : 0) + (z>f_z ? 4 : 0)
end
#Whether a octtree node contains the object.
function is_contained(in::OctTree, pos::(Number,Number,Number))
  half = node_size(in)/2
  x,y,z = pos
  ax,ay,az = in.pos
  return ax-half <= x <= ax+half &&
         ay-half <= y <= ay+half &&
         az-half <= z <= az+half 
end
#Which direction an octree might expand to to fit the thing.
function octtree_dirs(from::OctTree, pos::(Number,Number,Number))
  x,y,z = pos
  f_x,f_y,f_z = from.pos
  return (x>f_x, y>f_y, z>f_z)
end

function node_of_pos{T}(from::OctTree, thing::T)
  i = index_of_pos(from, thing)
  return i==0||from.arr==nothing ? nothing : from.arr[i]
end
node_of_pos(from::OctTree, pos::(Number,Number,Number)) =
    is(from.arr,nothing) ? nothing : from.arr[index_of_pos(from, pos)]

node_size(of::OctTree) = (2.0^(of.level+1))

#Keep going up levels until contained, or run out.
function up_to_contained{T}(from::OctTree, thing::T)
  while !is(from.parent,nothing) && !is_contained(from, thing)
    from = from.parent
  end
  return from
end
#Go up to some level.
function up_to_level(from::OctTree, level::Integer)
  while level > from.level && from.parent!=nothing
    from = from.parent
  end
  return from
end
up_to_top(of::OctTree) = up_to_level(of, typemax(Int16))

function down_to_level{T}(from::OctTree, thing::T, level::Integer)
  assert( level <= from.level )
  assert( is_contained(from, thing) )
  while level < from.level #Go down until level==from.level
    if is(from.arr, nothing) #at end.
      return from
    end
    i = index_of_pos(from, thing)
    if i==0 #Can't go down more
      return from
    end
    from = from.arr[i]
  end
  return from 
end
#Slightly slimmer version, with specific type.
function down_to_level(from::OctTree, pos::(Number,Number,Number),
                       level::Integer)
  assert( level <= from.level )
  assert( is_contained(from, pos) )
  while level < from.level #Go down until level==from.level
    next = node_of_pos(from, pos)
    if next==nothing #at end.
      return from
    end
    from = next
  end
  return from 
end

#Go to some level at a position in a quad tree, stopping when the tree ends.
function to_level{T}(from::OctTree, thing::T, level::Integer)
  from = up_to_level(from, level)
  if from.parent==nothing && level > from.level || level == from.level
    return from #Hit highest node or happy with it.
  end
  from = up_to_contained(from, thing)
  if !is_contained(from, thing) || level == from.level #Got/couldn't go there
    return from  
  end
  return down_to_level(from, thing, level)
end
