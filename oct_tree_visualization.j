#
#  Copyright (C) 22-08-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#Visualization of the oct tree for testing & behavior observation. 

#Draw a single node in lines.
function draw_lines_at(at::OctTree)
  s = 2*2.0^at.level
  x,y,z = (at.x-s/2, at.y-s/2, at.z-s/2)
  function loop_at_z(z)
    @with_primitive GL_LINE_LOOP begin
      glvertex(x,  y,  z)
      glvertex(x,  y+s,z)
      glvertex(x+s,y+s,z)
      glvertex(x+s,y,  z)
    end
  end
  loop_at_z(z)
  loop_at_z(z+s)
#
  function vertex_pair(x,y)
    glvertex(x,y,z)
    glvertex(x,y,z+s)
  end
  @with_primitive GL_LINES begin
    vertex_pair(x,  y)
    vertex_pair(x,  y+s)
    vertex_pair(x+s,y+s)
    vertex_pair(x+s,y)
  end
end
#Draw the given node and the lower nodes in lines
#function draw_lines_lower(at::OctTree, downto_level::Integer)
#  if at.level < downto_level
#    return nothing
#  end
#  draw_lines_at(at)
#  for lower in at.arr
#    if lower!=nothing
#      draw_lines_lower(lower, downto_level)
#    end
#  end
#end
#draw_lines_lower(at::OctTree) = draw_lines_lower(at, typemin(Int16)) #All of them.
##Draw all lines, including up, unless below some level.
function draw_lines_whole(of::OctTree, 
                          upto_level::Integer,downto_level::Integer)
  for q = OctTreeIter(of, upto_level,downto_level)
    draw_lines_at(q)
  end
end

draw_lines_whole(at::OctTree) = 
    draw_lines_whole(at, typemax(Int16),typemin(Int16)) #All of them.
