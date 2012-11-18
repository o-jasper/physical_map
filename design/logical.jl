#
#  Copyright (C) 18-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#inside_p(a,b) status of b being inside of a, returning one of the following:
type Partial end
type MaybePartial end
type Outside end
type Inside end

#And the 'logical' objects:
type ObjAndNot{A,B} #difference
    inside::A
    not::B
end
function inside_p{A,B,T}(andnot::ObjAndNot{A,B}, thing::T) 
    @case inside(andnot.not, thing) begin
        Inside                 : Outside
        if Partial | MaybePartial
            return (inside(andnot.inside, thing) == Outside ? 
                    Outside : MaybePartial)
        end
        Outside : inside(andnot.inside,thing)
    end
end

type ObjAnd{T} #Intersection
    list::Array{T,1}
end
function inside_p{A,B,T}(obj::ObjAndNot{A,B}, thing::T)
    partial_p = false
    for el in obj.list
        @case inside(el, thing) begin
            Outside                 : return Outside
            Partial | MaybePartial  : partial_p = true 
        end
    end
    return (partial_p ? MaybePartial : Inside)
end

type ObjOr{T} #Union
    list::Array{T,1}
end
function inside_p{A,T}(obj::ObjOr{A}, thing::T)
    partial_cnt = 0
    for el in obj.list
        @case inside(el, thing) begin
            Inside       : return Inside
            Partial      : partial_cnt += 1
            MaybePartial : partial_cnt += 2
        end
    end
    return (partial_cnt==1 ? Partial : (partial_cnt>1 ? MaybePartial : Outside))
end
