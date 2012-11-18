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
inside{Obj,T}(obj::MatrixTransfo{Obj}, thing::T) =
    inside(obj.object, obj.matrix*thing)

type TranslateTransfo{Obj}
    delta::Vector{Float}
    object::Obj
end
inside{Obj,T}(obj::TranslateTransfo{Obj}, thing::T) =
    inside(obj.object, thing + obj.delta)
