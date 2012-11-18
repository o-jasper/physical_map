#
#  Copyright (C) 09-09-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

typealias Block ((Number,Number,Number),(Number,Number,Number))

#Defining geometrically_surrounding, you can use these:
size_under{T}(in::OctTree, thing::T) = 
    sizeof_under(in, geometrically_surrounding(thing))
is_contained{T}(in::OctTree, thing::T) =
    index_of_pos(in, geometrically_surrounding(thing))
octree_dirs{T}(in::OctTree, thing::T) =
    index_of_pos(in, geometrically_surrounding(thing))

#Block.
function index_of_pos(in::OctTree, block::Block)
  f,t = block
  i_f = index_of_pos(in,f)
  i_t = index_of_pos(in,t)
  return i_f==i_t ? i_f : 0 #Zero indicates it doesn't fit.
end

function is_contained(in::OctTree, block::Block)
  f,t = block
  return is_contained(in,f) &&is_contained(in,t)
end
#Which direction to drop the block down to.
function octree_dirs(from::OctTree, block::Block)
  (fx,fy,fz), (tx,ty,tz) = block
  f_x,f_y,f_z = from.pos
  
  md(x, a,b) = ((abs(x-a) > abs(x-b)) ? x > a : x > b)
  
  return (md(f_x,fx,tx), md(f_y,fy,ty), md(f_z,fz,tz))
end

#TODO line segment.
type LineSegment
  s::(Float64,Float64,Float64)
  t::(Float64,Float64,Float64)
  function LineSegment(s::(Number,Number,Number), t::(Number,Number,Number))
    sx,sy,sz = s
    tx,ty,tz = t
    return new((float64(sx),float64(sy),float64(sz)), (float64(ex),float64(ey),float64(ez)))
  end
end

function overlap_p(block::Block, line::LineSegment)
  sx,sy,sz = line.s
  ex,ey,ez = line.e
  (fx,fy,fz), (tx,ty,tz) = block
  
  
end