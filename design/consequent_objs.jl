#
#  Copyright (C) 18-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#Objects made from other stuff. The `obj` method actually makes the objects.

inside_p{Obj,T}(p::Obj, thing::T) = inside_p(obj(p), thing)
*{Obj,M}(m::M, p::Obj) = m*obj(p)
+{Obj,V}(v::V, p::Obj) = v+obj(p)

type Cylinder
    r::Float64
    min::Float64
    max::Float64
    dir::Vector{Float64}

    Cylinder(r::Number, min::Number,max::Number, dir::Vector, 
             normalize_p::Bool) = 
        new(float64(r),float64(min),float64(max), 
            float64(normalize_p ? dir/norm(dir) : dir))
end
inside_p{T}(c::Cylinder

cylinder(r::Number, min::Number,max::Number, dir::Vector) =
    cylinder(r,min,max,dir, true)
cylinder(r::Number, min::Number,max::Number) =
    cylinder(r, min,max, [0,0,1], false)
cylinder(r::Number, min::Number) =
    cylinder(r, min,typemax(Float64))
cylinder(r::Number) =
    cylinder(r, typemin(Float64))
cylinder(r::Number, dir::Vector) =
    cylinder(r, typemin(Float64),typemax(Float64), dir)
function cylinder(r::Number, opts::Options)
    @defaults opts min=typemin(Float64) max=typemax(Float64) dir = [0,0,1]
    return cylinder(r,min,max,dir)
end

function flattening_matrix(dir::Vector)
    a = float64(dir[2]!=0 ? cross(dir, [0,0,1]) : cross(dir, [1,0,0]))
    b = float64(cross(a,dir))
    return [a b float64([0,0,0])]
end
function obj(c::Cylinder)
    mt = MatrixTransfo(OrthoMatrix(flattening_matrix(c.dir), true),
                       sphere(c.r))
    if min!=typemin(Float64)
        push(list, Surface(min,-dir))
    end
    if max!=typemax(Float64)
        push(list, Surface(max,dir))
    end
    return (length(list)>1 ? ObjAnd(list) : mt)
end

type Block
    f::Vector{Float64}
    t::Vector{Float64}
end

#NOTE/TODO probably this will be the top computational expense.
function obj(b::Block) #Cube is done by making the corresponding Convex.
    fx,fy,fz = b.f[1],b.f[2],b.f[3]
    tx,ty,tz = b.t[1],b.t[2],b.t[3]
    positions = Array(Vector{Float64},0)
    begin
        addpos(v) = push(positions, float(v))
        addpos([fx, fy, fz]) #The corners.
        addpos([tx, fy, fz])
        addpos([fx, ty, fz])
        addpos([tx, ty, fz])
        addpos([fx, fy, tz])
        addpos([tx, fy, tz])
        addpos([fx, ty, tz])
        addpos([tx, ty, tz])
    end
    surfaces = Array(Surface,0)
    begin
        addsurf(inpr::Number, n::Vector) = 
            push(surfaces, Surface(float64(inpr),float64(n)))
        addsurf(tx, [+1, 0,  0])
        addsurf(fx, [-1, 0,  0])
        addsurf(ty, [0, +1,  0])
        addsurf(fx, [0, -1,  0])
        addsurf(tz, [0,  0, +1])
        addsurf(fz, [0,  0, -1])
    end
    return Convex(positions, surfaces)
end

type Cube
    size::Vector{Float64}
    center::Bool
end
cube(size::Vector, center::Bool) = Cube(float64(size),center)
cube(size::Vector) = Cube(float64(size), false)
function cube(size::Vector, opts::Options)
    @defaults opts center=false
    return Cube(float64(size), center)
end
obj(c::Cube) = obj(c.center ? Block(-size/2,size/2) : Block(float64([0,0,0]), size))