#
#  Copyright (C) 19-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

load("util/util.jl")
load("util/get_c.jl")

load("autoffi/gl.jl")
load("ffi_extra/gl.jl")

load("sdl_bad_utils/sdl_bad_utils.jl")

using GetC, OJasper_Util, SDL_BadUtils, AutoFFI_GL, FFI_Extra_GL

load("physical_map/oct/octtree.jl")
#load("physical_map/oct/tree.j")
#load("physical_map/oct/expand.j")
#load("physical_map/oct/iter.j")
load("physical_map/oct/visualization.jl")

using OctTreeModule, OctTreeVisualization

load("Options.jl")
using OptionsMod

#TODO no module for it yet.
load("physical_map/design/logical.jl")
load("physical_map/design/transfo.jl")
load("physical_map/design/primitives.jl")
load("physical_map/design/objs.jl")

load("physical_map/design/octo.jl")

function run_this ()
  screen_width = 640
  screen_height = 640
  init_stuff()

  mx(i) = -1 + 2*i/screen_width
  my(j) = +1 - 2*j/screen_height
  mx()  = mx(mouse_x())
  my()  = my(mouse_y())

  ot = OctTree(1)
  #TODO 'depth histograms' inside and outside.
  @time octfill_deepen(ot, translate(0.4,0.4, scale(1,2, sphere(1))), -7)
  
  glpointsize(4)
  init_t = time()
  while true
    @with glpushed() begin
      if time()%4 < 2
        glrotate(30, 1,1,1)
        glrotate(10*(time()-init_t),0.1,0.4,1)
      end
      glscale(2.0^-2)
      if time()%8<4
          glcolor(1,1,1)
#          draw_lines_whole(ot)
      end
      #TODO draw the thing, non-lines
      glcolor(0,0.4,0)
      draw_block(ot)
    end
    
    @with glprimitive(GL_TRIANGLES) begin
      glcolor(1.0,0.0,0.0)
      glvertex(mx(),my())
      glvertex(mx()+0.1,my())
      glvertex(mx(),my()+0.1)
    end
    finalize_draw() #TODO event catcher to rotate around the thing.
    flush_events()
  end
end

run_this()
