
#...

#_example_ part of juliarc
begin
  # Don't want trouble with people thinking that is a julia variable, or it
  # becoming one in the future and having a bad time.
  local user="jasper" 
  local proj="/home/$user/proj"
#NOTE that used to be /src/julia-src/ (and this is about it's dependency)
  push(LOAD_PATH, "$proj/common-lisp/parse-c-header/julia-src/")
  push(LOAD_PATH, "$proj/julia/julia-glplot/")
end

#....

for path in LOAD_PATH #At end.
  size = filesize(path)
  assert( size>0, "Seems like path in LOAD_PATH doesn't exist.
size $size (using filesize as proxy. TODO find file_exists)")
end
