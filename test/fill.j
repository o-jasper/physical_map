#
#  Copyright (C) 22-08-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

load("load_so.j")
load("get_c.j")
load("sdl_bad_utils/init_stuff.j")

load("autoffi/gl.j")
load("gl_util.j")

load("sdl_bad_utils/sdl_event.j")

load("universe_map/oct_tree.j")
load("universe_map/oct_tree_expand.j")
load("universe_map/oct_iter.j")
load("universe_map/oct_tree_visualization.j")

load("universe_map/oct_list.j")

type ListManner
end

type FillObj
  pos::(Float64,Float64,Float64)
  natural_level::Int16
  function FillObj(pos::(Number,Number,Number), natural_level::Int16)
    x,y,z = pos
    return new((float64(x),float64(y),float64(z)), natural_level)
  end
end

FillObj(pos::(Number,Number,Number), size::Number) = FillObj(pos, natural_level(size))



function add_obj{O}(to::OctTree, obj::O, m::ListManner)
  if to.content == nothing
    to.content = {obj}
  else
    push(to.content, obj)
  end
  return length(to.content) > 20
end
#NOTE: an idea is to have the iterators drop things..
function after_deepen(of::OctTree, m::ListManner)
  list = m.content
  m.content = {}
  while !isempty(list)
    el = pop(list)
    if el.natural_level < of.level # Should go down.
      add_obj(of, el, m)
    else #Should stay.
      push(m.content, el)
    end
  end
end

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
    @with_pushed_matrix begin
      glrotate(30, 1,1,1)
      glscale(2.0^-2)
      glcolor(1,1,1)
      draw_lines_whole(ot)
      glcolor(1,1,0)
      @with_primitive GL_POINTS for el in list
        x,y,z = el
        glvertex(x,y,z)
      end
    end
    
    @with_primitive GL_TRIANGLES begin
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
