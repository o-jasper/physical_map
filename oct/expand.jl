#
#  Copyright (C) 09-09-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#Deepen whole array
function deepen_1_whole(from::OctTree)
  x,y,z = from.pos
  s = node_size(from)/4
  from.arr = [OctTree(from, (x-s, y-s, z-s)), #Binary count up with  - and + there.
              OctTree(from, (x+s, y-s, z-s)),
              OctTree(from, (x-s, y+s, z-s)),
              OctTree(from, (x+s, y+s, z-s)),
              
              OctTree(from, (x-s, y-s, z+s)),
              OctTree(from, (x+s, y-s, z+s)),
              OctTree(from, (x-s, y+s, z+s)),
              OctTree(from, (x+s, y+s, z+s))]
end

function deepen_1_whole(from::OctTree, assert_p::Bool)
  if assert_p
    assert( is(from.arr, nothing) )
  end
  deepen_1_whole(from)
end

#Expand one octtree up.
function create_upside_octtree(from::OctTree, dirs::(Bool,Bool,Bool))
  stepsize = node_size(from)/2
  step(way::Bool) = (way ? stepsize : -stepsize)
  dx,dy,dz = dirs
  f_x,f_y,f_z = from.pos
  new = OctTree(nothing, from.level+1, #no parent, of course.
                (f_x + step(dx),f_y + step(dy),f_z + step(dz)))
  deepen_1_whole(new) #Deepen it to put the parent in one.
  new.arr[index_of_pos(new, from.pos)] = from #Register as child.
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

function expand_up_to_contained{T}(from::OctTree, thing::T)
  from = up_to_contained(from, thing)
  assert(is_contained(from,thing) || from.parent==nothing, 
         "`up_to_contained`, didn't go to either max not containment.")
  while !is_contained(from, thing)
    from.parent = create_upside_octtree(from, octtree_dirs(from,thing))
    from = from.parent
  end
  assert(is_contained(from,thing), "BUG")
  return from
end

function expand_down_to_level{T}(from::OctTree, thing::T,level::Integer)
  assert( is_contained(from, thing) )

  from = to_level(from, thing,level)
  while level < from.level #Need to deepen it.
    deepen_1_whole(from::OctTree, true)
    
    i = index_of_pos(from, thing)
    if i==0
      return from
    end
    from = from.arr[i]
  end
  return from
end

#Increase the completeness of the quad tree to some level.
function expand_to_level{T}(from::OctTree, thing::T,
                            level::Integer, expand_contain::Bool)
  from = expand_up_to_level(from, thing,level)
  if !is_contained(from, thing)
    if !expand_contain #Can't go down if not contained in current.
      return from
    end
    from = expand_up_to_contained(from, thing)
  end
  #The rest is down.
  return expand_down_to_level(from, thing, level)
end
expand_to_level{T}(from::OctTree, thing::T,level::Integer) =
    expand_to_level(from, thing,level, true) #!

function consistency_check_this(of::OctTree)
  assert(!is(of.parent,of), "Invalid state: Parent same as OctTree node")
  if !is(of.arr, nothing)
    for el in of.arr #TODO contains_is
      assert(!is(el,of), "Invalid state: Child same as OctTree node")
      if el!=nothing
        assert(is_contained(of, el.pos), "Invalid state: misplaced subtree")
      end
    end
  end
end

consistency_check_down(of::Nothing) = nothing
function consistency_check_down(arr::Array{OctTree,1})
  for el in arr
    consistency_check_down(el)
  end
end
function consistency_check_down(of::OctTree)
  consistency_check_this(of)
  consistency_check_down(of.arr)
end

function consistency_check(of::OctTree)
  while !is(of.parent,nothing)
    assert(!is(of.parent,of), #If you're fixing holes in the road, dont trip.
           "Invalid state: Parent same as OctTree node")
    of = of.parent
  end
  consistency_check_down(of)
end
