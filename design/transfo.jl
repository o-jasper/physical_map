#
#  Copyright (C) 18-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#Orthogonality implies useful properties.
type OrthoMatrix
    m::Array{Float64,2}
    flatten::Bool #Not quite orthogonal, flattens thing in question.
end
*(matrix::OrthoMatrix, v::Vector{Float64}) = matrix.m*v

type MatrixTransfo{M,Obj} #TODO inside's for these two.
    matrix::M
    object::Obj
end
inside_p{Obj,T}(obj::MatrixTransfo{Obj}, thing::T) =
    inside_p(obj.object, obj.matrix*thing)

scale(v::Vector, obj) = MatrixTransfo(OrthoMatrix(diagm(float64(v)),false), obj)
scale(x,y,z, obj) = scale([x,y,z], obj)
scale(x,y, obj) = scale([x,y,1], obj)

type TranslateTransfo{Obj}
    delta::Vector{Float64}
    object::Obj
end
inside_p{Obj,T}(obj::TranslateTransfo{Obj}, thing::T) =
    inside_p(obj.object, obj.delta + thing)

translate(delta::Vector, obj) = TranslateTransfo(float64(delta),obj)
translate(x::Number,y::Number,z::Number, obj) = translate({x,y,z},obj)
translate(x::Number,y::Number, obj) = translate({x,y,0},obj)