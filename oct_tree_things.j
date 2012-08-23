#
#  Copyright (C) 23-08-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#Defining geometrically_surrounding, you can use these:
#(probably best to return a block as below)
index_of_pos{T}(in::OctTree, thing::T) =
    index_of_pos(in, geometrically_surrounding(thing))
is_contained{T}(in::OctTree, thing::T) =
    index_of_pos(in, geometrically_surrounding(thing))
octree_dirs{T}(in::OctTree, thing::T) =
    index_of_pos(in, geometrically_surrounding(thing))

#Block.
function index_of_pos(in::OctTree, 
                      block::((Number,Number,Number),(Number,Number,Number)))
  f,t = block
  i_f = index_of_pos(in,f)
  i_t = index_of_pos(in,t)
  return i_f==i_t ? i_f : 0 #Zero indicates it doesn't fit.
end

function is_contained(in::OctTree, 
                      block::((Number,Number,Number),(Number,Number,Number)))
  f,t = block
  return is_contained(in,f) &&is_contained(in,t)
end

function octree_dirs(from::OctTree,
                     block::((Number,Number,Number),(Number,Number,Number)))
  f,t = block
  fx,fy,fz = f
  tx,ty,tz = t
  f_x,f_y,f_z = from.pos
  
  md(x, a,b) = ((abs(x-a) > abs(x-b)) ? x > a : x > b)
  
  return (md(f_x,fx,tx), md(f_y,fy,ty), md(f_z,fz,tz))
end
