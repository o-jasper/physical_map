#
#  Copyright (C) 22-08-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#Note 2.0^.. not being integer sidesteps changes there.

typealias MaybeOctTree Any # Union(OctTree,Nothing)

function mk_nothing_arr()
  arr = Array(MaybeOctTree,0)
  for i = 1:8
    push(arr, nothing)
  end
  return arr
end

type OctTree
  parent::MaybeOctTree
  level::Int16 #Depth, size of current block is 2*2^(+level)
  pos::(Float64,Float64,Float64)
  
  arr::Array{MaybeOctTree,1}
  
  list::Array{Any,1} #TODO template it?

  function OctTree(parent,level::Integer, pos::(Number,Number,Number))
    x,y,z = pos
    return new(parent,int16(level), (float64(x),float64(y),float64(z)),
               mk_nothing_arr(), Array(Any,0))
  end
end

function children_cnt(o::OctTree)
  cnt = 0
  for el in o.arr
    if el!=nothing
      cnt+=1
    end
  end
  return cnt
end

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

#Gets the index of the array where the subnodes live.
function index_of_pos(from::OctTree, pos::(Number,Number,Number))
  x,y,z = pos
  f_x,f_y,f_z = from.pos
  return 1+(x>f_x ? 1 : 0) + (y>f_y ? 2 : 0) + (z>f_z ? 4 : 0)
end
#Whether a octtree node contains the object.
function is_contained(at::OctTree, pos::(Number,Number,Number))
  half = node_size(at)/2
  x,y,z = pos
  ax,ay,az = at.pos
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

node_of_pos(from::OctTree, pos::(Number,Number,Number)) =
    from.arr[index_of_pos(from, pos)]

node_size(of::OctTree) = (2.0^(of.level+1))

#Keep going up levels until contained, or run out.
function up_until_contained{T}(from::OctTree, thing::T)
  while from.parent!=nothing && !is_contained(from, thing)
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
    i = index_of_pos(from, thing)
    if i==0 #Can't go down more
      return from
    end
    if from.arr[i]==nothing #at end.
      return from
    end
    from = from.arr[i]
    assert(is_contained(from, thing),
           "Escaped containment going down? 
$thing, $level
$(from.pos) $(from.level)
$(is_contained(from, thing))")
  end
  return from 
end

#Go to some level at a position in a quad tree, stopping when the tree ends.
function to_level{T}(from::OctTree, thing::T, level::Integer)
  from = up_to_level(from, level)
  if from.parent==nothing && level > from.level || level == from.level
    return from #Hit highest node or happy with it.
  end
  from = up_until_contained(from, thing)
  if !is_contained(from, thing) || level == from.level #Got/couldn't go there
    return from  
  end
  return down_to_level(from, thing, level)
end

#Expand one octtree up.
function create_upside_octtree(from::OctTree, dirs::(Bool,Bool,Bool))
  stepsize = node_size(from)/2
  step(way::Bool) = (way ? stepsize : -stepsize)
  dx,dy,dz = dirs
  f_x,f_y,f_z = from.pos
  new = OctTree(nothing, from.level+1, #no parent, of course.
                (f_x + step(dx),f_y + step(dy),f_z + step(dz)))
  i = index_of_pos(new, from.pos)
  new.arr[i] = from #Register as child.
  return new
end

function expand_up_to_level{T}(from::OctTree, thing::T,#TODO type
                              level::Integer, #Latter are directions to go to.
                              dirs::(Bool,Bool,Bool))
  from = to_level(from,thing,level) #Go there as far as possible
  while level > from.level
    assert(from.parent==nothing, "Aught to be expanding upward,\
but already stuff there.")
    from.parent = create_upside_octtree(from, dirs)
    from = from.parent
  end
  return from
end
expand_up_to_level{T}(from::OctTree, thing::T,level::Integer) = #!
    expand_up_to_level(from, thing,level, octtree_dirs(from,thing))

function expand_up_to_contained{T}(from::OctTree, thing::T, level::Integer)
  while !is_contained(from, thing)
    assert(from.parent==nothing, "Don't need to expand up to contain.")
    from.parent = create_upside_octtree(from, octtree_dirs(from,thing))
    from = from.parent
  end
  assert( is_contained(from,thing) )
  return from
end

function expand_down_to_level{T}(from::OctTree, thing::T,level::Integer)
  assert( is_contained(from, thing) )
  while level < from.level #Need to deepen it.
    i = index_of_pos(from, thing)
    if i==0
      return from
    end
    stepsize = node_size(from)/4
    step(way::Bool) = (way ? stepsize : -stepsize)
    #Make a quadtree node down there and go there.
    dx,dy,dz = octtree_dirs(from,thing)
    x,y,z = from.pos
    from.arr[i] = OctTree(from, (x + step(dx), y + step(dy),z + step(dz)))
    from = from.arr[i]
  end
  return from
end

#Increase the completeness of the quad tree to some level.
function expand_to_level{T}(from::OctTree, thing::T,
                            level::Integer, expand_contain::Bool)
  from = expand_up_to_level(from, thing,level)
  from = up_until_contained(from, thing) #Try get contained.
  if !is_contained(from, thing)
    if !expand_contain #Can't go down if not contained in current.
      return from
    end
    from = expand_up_to_contained(from, thing, level)
  end
  from = to_level(from, thing,level)
  #The rest is down.
  return expand_down_to_level(from, thing, level)
end
expand_to_level{T}(from::OctTree, thing::T,level::Integer) =
    expand_to_level(from, thing,level, true) #!

function consistency_check_this(of::OctTree)
  assert(!is(of.parent,of), "Invalid state: Parent same as OctTree node")
  for el in of.arr #TODO contains_is
    assert(!is(el,of), "Invalid state: Child same as Octree node")
    if el!=nothing
      assert(is_contained(of, el.pos), "Invalid state: misplaced subtree")
    end
  end
end

consistency_check_down(of::Nothing) = nothing
function consistency_check_down(of::OctTree)
  consistency_check_this(of)
  map(consistency_check_down, of.arr)
end

function consistency_check(of::OctTree)
  while !is(of.parent,nothing)
    assert(!is(of.parent,of), #If you're fixing holes in the road, dont trip.
           "Invalid state: Parent same as OctTree node")
    of = of.parent
  end
  consistency_check_down(of)
end
