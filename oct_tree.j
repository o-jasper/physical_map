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
  x::Float64
  y::Float64
  z::Float64
  
  arr::Array{MaybeOctTree,1}
  
  list::Array{Any,1} #TODO template it?

  OctTree(parent,level::Integer, x::Number,y::Number,z::Number) =
      new(parent,int16(level), float64(x),float64(y),float64(z),
          mk_nothing_arr(), Array(Any,0))
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
  print("<OctTree level $(o.level), pos [$(o.x),$(o.y),$(o.z)]")
  if o.parent!=nothing
    print(" has parent")
  end
  println(" children_cnt $(children_cnt(o))>")
end

OctTree(parent::OctTree, x::Number,y::Number,z::Number) =
    OctTree(parent, parent.level-1, x,y,z)
OctTree(level::Integer, x::Number,y::Number,z::Number) =
    OctTree(nothing, level, x,y,z)
OctTree(level::Integer) = OctTree(level, 0,0,0)
OctTree() = OctTree(0)

#NOTE much better algorithm involving multiple levels on one structure and
# jumping straight to a node on them,,, Avoiding mission creep, i guess.

index_of_pos(from::OctTree,  x::Number,y::Number,z::Number) =
    1+(x>from.x ? 1 : 0) + (y>from.y ? 2 : 0) + (z>from.z ? 4 : 0)

node_size(of::OctTree) = (2.0^(of.level+1))

function is_contained(at::OctTree, x::Number,y::Number,z::Number)
  half = node_size(at)/2
  return at.x-half <= x <= at.x+half &&
         at.y-half <= y <= at.y+half &&
         at.z-half <= z <= at.z+half 
end

#Keep going up levels until contained, or run out.
function up_until_contained(from::OctTree, x::Number,y::Number,z::Number)
  while from.parent!=nothing && !is_contained(from, x,y,z)
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

function down_to_level(from::OctTree, x::Number,y::Number,z::Number, 
                       level::Integer)
  assert( level <= from.level )
  assert( is_contained(from, x,y,z) )
  while level < from.level #Go down until level==from.level
    next = from.arr[index_of_pos(from,x,y,z)]
    if next==nothing #At end.
      return from
    end
    from = next
    assert(is_contained(from, x,y,z),
           "Escaped containment going down? 
$(x,y,z), $level
$(from.x,from.y,from.z) $(from.level)
$(is_contained(from, x,y,z))")
  end
  return from 
end

#Go to some level at a position in a quad tree, stopping when the tree ends.
function to_level(from::OctTree, x::Number,y::Number,z::Number, 
                  level::Integer)
  from = up_to_level(from, level)
  if from.parent==nothing && level > from.level || level == from.level
    return from #Hit highest node.
  end
  from = up_until_contained(from,  x,y,z)
  if !is_contained(from, x,y,z) || level == from.level #Got/couldn't go there
    return from  
  end
  return down_to_level(from, x,y,z, level)
end

#Expand one octtree up.
function create_upside_octtree(from::OctTree, dirs::(Bool,Bool,Bool))
  stepsize = node_size(from)/2
  step(way::Bool) = (way ? stepsize : -stepsize)
  dx,dy,dz = dirs
  new = OctTree(nothing, from.level+1, #no parent, of course.
                from.x + step(dx),from.y + step(dy),from.z + step(dz))
  i = index_of_pos(new, from.x,from.y,from.z)
  new.arr[i] = from #Register as child.
  return new
end

function expand_up_to_level(from::OctTree, x::Number,y::Number,z::Number, 
                            level::Integer, #Latter are directions to go to.
                            dirs::(Bool,Bool,Bool))
  from = to_level(from, x,y,z,level) #Go there as far as possible
  while level > from.level
    assert(from.parent==nothing, "Aught to be expanding upward,\
but already stuff there.")
    from.parent = create_upside_octtree(from, dirs)
    from = from.parent
  end
  return from
end
expand_up_to_level(from::OctTree,
                   x::Number,y::Number,z::Number,level::Integer) = #!
    expand_up_to_level(from, x,y,z,level, (x>from.x, y>from.y, z>from.z))

function expand_up_to_contained(from::OctTree, x::Number,y::Number,z::Number, 
                                level::Integer)
  while !is_contained(from, x,y,z)
    assert(from.parent==nothing, "Don't need to expand up to contain.")
    from.parent = create_upside_octtree(from, (x>from.x, y>from.y, z>from.z))
    from = from.parent
  end
  assert( is_contained(from,x,y,z) )
  return from
end

function expand_down_to_level(from::OctTree, x::Number,y::Number,z::Number, 
                              level::Integer)
  assert( is_contained(from, x,y,z) )
  while level < from.level #Need to deepen it.
    i = index_of_pos(from, x,y,z)
    stepsize = node_size(from)/4
    step(way::Bool) = (way ? stepsize : -stepsize)
    #Make a quadtree node down there and go there.
    from.arr[i] = 
      OctTree(from, from.x + step(x>from.x), 
              from.y + step(y>from.y),from.z + step(z>from.z))
    from = from.arr[i]
  end
  return from
end

#Increase the completeness of the quad tree to some level.
function expand_to_level(from::OctTree, x::Number,y::Number,z::Number, 
                         level::Integer, expand_contain::Bool)
  from = expand_up_to_level(from, x,y,z,level)
  from = up_until_contained(from,  x,y,z) #Try get contained.
  if !is_contained(from, x,y,z)
    if !expand_contain #Can't go down if not contained in current.
      return from
    end
    from = expand_up_to_contained(from, x,y,z, level)
  end
  from = to_level(from, x,y,z,level)
  #The rest is down.
  return expand_down_to_level(from, x,y,z, level)
end
expand_to_level(from::OctTree, x::Number,y::Number,z::Number,level::Integer) =
    expand_to_level(from, x,y,z,level, true) #!

function consistency_check_this(of::OctTree)
  assert(!is(of.parent,of), "Invalid state: Parent same as OctTree node")
  for el in of.arr #TODO contains_is
    assert(!is(el,of), "Invalid state: Child same as Octree node")
    if el!=nothing
      assert(is_contained(of, el.x,el.y,el.z), 
             "Invalid state: misplaced subtree")
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
