#
#  Copyright (C) 18-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#Convexes can be transformed easily. Cubes and lines(for instance) are convexes.
# The strategy is to transform the convexes to have `inside_p`'s calculatable
# Further, union,intersection and difference is implemented.

type Sphere #Always at 0,0,0(translate to move it)
    r::Float64
end
sphere(r::Number) = Sphere(float64(r))

type Surface #Single surface.
    inpr::Float64
    n::Vector{Float}
end
function surface(inpr::Number, normal::Vector) 
    len = norm(normal)
    return Surface(float64(inpr/len),float64(normal/len))
end
surface(pos::Vector, normal::Vector) = surface(dot(normal,pos),normal)

type Convex
    positions::Vector{Vector{Float64}} #Positions.
    surfaces::Vector{Surface} #Surfaces.
end

#Position inside plane?
inside_p(surface::Surface, pos::Vector{Float64}) =
    ( dot(pos, surface.n) <= surface.inpr ? Inside : Outside )

#Position inside sphere?
inside_p(sphere::Sphere, pos::Vector{Float64}) = 
    (norm(pos)<sphere.r ? Inside : Outside)
#Sphere inside surface
inside_p(surface::Surface, sphere::Sphere) = 
    ((sphere.r <= surface.inpr) ? Inside : (-sphere.r >surface.inpr ? 
                                            Outside : Partial))

#Position inside convex?
function inside_p(c::Convex, pos::Vector{Float64})
    for surface in c.surfaces
        if inside_p(surface,pos) == Outside
            return Outside
        end
    end
    return Inside
end
#Convex b in convex a?
function inside_p(a::Convex, b::Convex)
    any_inside = false
    any_outside = false
    for el in b.positions
        if (inside_p(a,el) == Inside)
            any_inside = true
        else
            any_outside = true
        end
        if any_inside && any_outside
            return Partial
        end
    end
    return (any_inside ? Inside : Outside)
end
#Convex in sphere?
function inside_p(sphere::Sphere, c::Convex)
    if inside_p(c, zero(c.positions[1]))
        for p in c.positions
            if norm(p) > sphere.r
                return Partial
            end
        end
        return Inside
    end
    for surf in c.surfaces
        if surf.inpr <= sphere.r
            return Outside
        end
    end
    return Partial #Needs to be all of them.
end
#Sphere in convex?
#function inside_p(c::Convex, sphere::Sphere)
#    any_outside, any_inside = false,false
#    for el in c.positions
#        outside_p = (sphere.r > norm(el))
#        any_outside = any_outside || outside_p
#        any_inside  = any_inside || !outside_p
#        if any_inside && any_outside
#            return Partial
#        end
#    end
#    assert( any_inside != any_outside  )
#    return (any_inside ? Inside : Outside)
#end

#Calling it *,+ makes sense, right?

+(delta::Vector{Float64}, surface::Surface) = 
    Surface(surface.inpr - dot(surface.n,delta), s.n)
+(delta::Vector{Float64}, c::Convex) =
    Convex(map((x)->x+delta, c.positions), map((x)->x+delta, c.surface))

#TODO hope that is right.
function *(matrix::Array{Float64,2}, surface::Surface)
    n = surface.n\(transpose(matrix)
    len = norm(n)
    return Surface(surface.inpr/len, n/len)
end
*{T}(thing::T, c::Convex) = #Elements of the convex dont care about whole.
    Convex(map(x->(thing*x), c.positions), map(x->thing*x, c.surfaces))

function *(matrix::OrthoMatrix, surface::Surface)
    n = matrix.m*surface.n #Uses property that the transpose(M)==inverse(M).
    len = norm(n)
    return Surface(surface.inpr/len, n/len)
end
