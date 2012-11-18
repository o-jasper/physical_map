#
#  Copyright (C) 18-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

type OctFill
    total::Bool
    partial::Bool
end

draw(of::OctFill, f::(Float64,Float64,Float64), t::(Float64,Float64,Float64)) =
    (of.total ? draw(f,t) : nothing)

function draw(f::(Float64,Float64,Float64), t::(Float64,Float64,Float64))
    fx,fy,fz = f
    tx,ty,tz = t
    function glpair(x,y)
        glvertex(x,y,fz)
        glvertex(x,y,tz)
    end
    @with glprimitive(GL_QUAD_STRIP) begin #Wall
        glpair(fx,fy)
        glpair(fx,ty)
        glpair(tx,ty)
        glpair(tx,fy)
        glpair(fx,fy)
    end
    function glhor(z)
        glvertex(fx,fy,z)
        glvertex(fx,ty,z)
        glvertex(tx,fy,z)
        glvertex(tx,ty,z)
    end
    @with glprimitive(GL_QUADS) begin #roof & ceiling
        glhor(fz)
        glhor(tz)
    end
end

function draw(oct::OctTree)
    x,y,z = oct.pos
    s = node_size(oct)
    draw(oct.content, oct.pos, (x+s,y+s,z+s))
end

function octfill_deepen(tree::OctTree, with, to_level::Integer)
    x,y,z = tree.pos
    s = node_size(oct)
    @case inside_p(with, Block([x,y,z],[x+s,y+s,z+s])) begin
        #Know the entire block is full/empty.
        Inside  : tree.content = OctFill(true,false) 
        Outside : tree.content = OctFill(false,false)
        if Partial | MaybePartial #Dont know, go down more.
            tree.content = OctFill(false,true)
            if tree.level<to_level
                deepen_1_whole(tree)
                for el in from.arr
                    octfill_deepen(el, with, to_level)
                end
            end
        end
    end
end
