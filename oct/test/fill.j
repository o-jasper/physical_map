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

load("universe_map/oct/tree.j")
load("universe_map/oct/expand.j")
load("universe_map/oct/iter.j")
load("universe_map/oct/visualization.j")

load("universe_map/oct/things.j")
load("universe_map/oct/list.j")

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

octtree_pos(fo::FillObj) = fo.pos
octtree_dirs(at::OctTree, fo::FillObj) = octtree_dirs(at,fo.pos)

FillObj(pos::(Number,Number,Number), size::Number) = FillObj(pos, natural_level(size))

is_contained(in::OctTree, obj::FillObj) = 
   (in.level >= obj.natural_level && is_contained(in, obj.pos))
natural_level(obj::FillObj) = obj.natural_level

function draw_lines(obj::FillObj)
  x,y,z = obj.pos
  s = 2.0^obj.natural_level
  draw_lines_cube(obj.pos, (x+s,y+s,z+s))
end

function enter_obj{O}(to::OctTree, obj::O, m::ListManner)
  if is(to.content, nothing)
    to.content = {obj}
  else
    push(to.content, obj)
  end
  if is(to.arr, nothing) && length(to.content)>=20
    may_deepen(to, m)
  end
end
#NOTE: an idea is to have the iterators drop thingsa..
function may_deepen(of::OctTree, m::ListManner)
  deepen_1_whole(of, true)
  list = of.content
  of.content = {}
  while !isempty(list)
    el = pop(list)
    if el.natural_level < of.level # Should go down.
      add_obj(of, el, m)
    else #Should stay.
      push(of.content, el)
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

  while true
    @with_pushed_matrix begin
#      glrotate(30*(1+sin(time()))/2, 1,1,1)
      glscale(2.0^-2)
      
      for q = iter_whole(ot)
        if !is(q.content,nothing)
          for el in q.content
            glcolor(0,0,1) #Draw objects.
            @with_primitive GL_LINES begin
              glvertex(el.pos)
              glvertex(q.pos)
            end
            glcolor(1,1,0) #Draw objects.
            draw_lines(el)
          end
        end
      end
      glcolor(1,1,1) #Draw oct tree.
      draw_lines_whole(ot)
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
      gen = FillObj((-2+4*rand(),-2+4*rand(), 0.01), #-1+2*rand()), 
                    0.01 + 0.1*randexp())
      add_obj(ot, gen, ListManner())
      next_t = time() + wait_t
      consistency_check(ot)
    end
  end
end

run_this()
