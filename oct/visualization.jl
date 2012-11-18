#
#  Copyright (C) 09-09-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

module OctTreeVisualization
#Visualization of the oct tree for testing & behavior observation. 

import Base.*, OJasper_Util.*, OctTreeModule.*
import AutoFFI_GL.*, FFI_Extra_GL.*

export draw_lines_at, draw_lines_whole 

function draw_lines_cube(f::(Number,Number,Number), t::(Number,Number,Number))
  fx,fy,fz = f
  tx,ty,tz = t
  function hor_loop (z)
    @with glprimitive(GL_LINE_LOOP) begin
      glvertex(fx,fy,z)
      glvertex(tx,fy,z)
      glvertex(tx,ty,z)
      glvertex(fx,ty,z)
    end
  end
  hor_loop(fz)
  hor_loop(tz)
  function vert_line(x,y)
    glvertex(x,y,fz)
    glvertex(x,y,tz)
  end
  @with glprimitive(GL_LINES) begin
    vert_line(fx,fy)
    vert_line(fx,ty)
    vert_line(tx,ty)
    vert_line(tx,fy)
  end
end

#Draw a single node in lines.
function draw_lines_at(at::OctTree) 
  hs = node_size(at)/2 
  x,y,z = at.pos
  draw_lines_cube((x-hs, y-hs, z-hs), (x+hs, y+hs, z+hs))
end
#Draw the given node and the lower nodes in lines
function draw_lines_whole(of::OctTree, downto_level::Integer)
  for q = iter_whole(of, downto_level)
    draw_lines_at(q)
  end
end

draw_lines_whole(at::OctTree) = 
    draw_lines_whole(at, typemin(Int16)) #All of them.

end #module OctTreeVisualization