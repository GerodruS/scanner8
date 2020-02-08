pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--main
function _init()
 planet_center={63.5,63.5}
 planet_radius=10
 scanner_pos={63,63}
 sources={}
 
 generate_sources()
end

function _update60()
 local d={0,0}
 local input=false
 if (btn(⬆️)) d[2]-=1 input=true
 if (btn(⬇️)) d[2]+=1 input=true
 if (btn(⬅️)) d[1]-=1 input=true
 if (btn(➡️)) d[1]+=1 input=true
 
 if input then
	 vnorm(d)
	 vscale(d,1)
	 vadd(scanner_pos,d)
	 local r=vdist(scanner_pos,planet_center)
  if planet_radius<r then
   vsub(scanner_pos,planet_center)
   vnorm(scanner_pos)
	  vscale(scanner_pos,planet_radius)
   vadd(scanner_pos,planet_center)
  end
 end
end

function _draw()
 cls()
-- pset(planet_center[1],planet_center[2],7)
 circ(planet_center[1],planet_center[2],planet_radius+1,7)
 
 local best_i=get_closest_source(scanner_pos)
 for i=1,count(sources) do
  local c=best_i[1]==i and 9 or 3
  pset(sources[i][1],sources[i][2],c)
 end
 
 pset(scanner_pos[1],scanner_pos[2],8)
end
-->8
--vector math
function vnorm(v)
 local l=sqrt(v[1]^2+v[2]^2)
 v[1]/=l
 v[2]/=l
end

function vadd(a,b)
 a[1]+=b[1]
 a[2]+=b[2]
end

function vsub(a,b)
 a[1]-=b[1]
 a[2]-=b[2]
end

function vscale(v,s)
 v[1]*=s
 v[2]*=s
end

function vdist(a,b)
 return sqrt(vdist2(a,b))
end

function vdist2(a,b)
 return (a[1]-b[1])^2+
        (a[2]-b[2])^2
end
-->8
function generate_sources()
 local r=planet_radius
 local d=r*2
	for i=1,5 do
	 local p={flr(rnd(d))-r,flr(rnd(d))-r}
	 local dist=vdist(p,{0,0})
  if r<dist then
   vnorm(p)
	  vscale(p,planet_radius)
	 end
	 vadd(p,planet_center)
	 add(sources,p)
	end
end

function get_closest_source(p)
 local best_d=planet_radius^2
 local best_i=nil
 for i=1,count(sources) do
  local d=vdist2(p,sources[i])
  if (d<best_d) best_d=d best_i=i
 end
 return {best_i,best_d}
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
