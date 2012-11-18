#
#  Copyright (C) 22-08-2012 Jasper den Ouden.
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

import GetC.*, OJasper_Util.*, SDL_BadUtils.*, AutoFFI_GL.*, FFI_Extra_GL.*

load("universe_map/oct/octtree.jl")
#load("universe_map/oct/tree.j")
#load("universe_map/oct/expand.j")
#load("universe_map/oct/iter.j")
load("universe_map/oct/visualization.jl")

import OctTreeModule.*, OctTreeVisualization.*


function run_this ()
  screen_width = 640
  screen_height = 640
  init_stuff()

  mx(i) = -1 + 2*i/screen_width
  my(j) = +1 - 2*j/screen_height
  mx()  = mx(mouse_x())
  my()  = my(mouse_y())

  wait_t = 0.1
  next_t = time() + wait_t
  expand_cnt = 0
  ot = OctTree(-4)
  println(ot)

  list = {} 
  glpointsize(4)
  while true
    @with glpushed() begin
      if time()%4 < 2
        glrotate(30, 1,1,1)
      end
      glscale(2.0^-2)
      glcolor(1,1,1)
      draw_lines_whole(ot)
      glcolor(1,1,0)
      @with glprimitive(GL_POINTS) for el in list
        x,y,z = el
        glvertex(x,y,z)
      end
    end
    
    @with glprimitive(GL_TRIANGLES) begin
      glcolor(1.0,0.0,0.0)
      glvertex(mx(),my())
      glvertex(mx()+0.1,my())
      glvertex(mx(),my()+0.1)
    end
    finalize_draw()
    flush_events()

    if next_t < time()
      gen = (-1+2*rand(),-1+2*rand(),-1+2*rand())
      push(list,gen)
      println("$expand_cnt $gen")
      expand_cnt += 1
      expand_to_level(ot, gen, -6)
      next_t = time() + wait_t
      consistency_check(ot)
    end
  end
end

run_this()
