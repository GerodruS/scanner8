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
	 vscale(d,0.5)
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
 
 local sp=vcpy(scanner_pos)
 vflr(sp)
 local best_i=get_closest_source(sp)
 for i=1,count(sources) do
  local c=best_i[1]==i and 9 or 3
  pset(sources[i][1],sources[i][2],c)
 end
 
 local resources=get_resources(sp)
 print(resources[1])
 print(resources[2])
 print(resources[3])
 print(resources[4])

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

function vflr(v)
 v[1]=flr(v[1])
 v[2]=flr(v[2])
end

function vcpy(v)
 return {v[1],v[2]}
end
-->8
--sources
function generate_sources()
 local r=planet_radius
 local d=r*2
 srand(0)
	for i=1,5 do
	 local p={flr(rnd(d))-r,flr(rnd(d))-r}
	 local dist=vdist(p,{0,0})
  if r<dist then
   vnorm(p)
	  vscale(p,planet_radius)
	 end
	 vadd(p,planet_center)
	 vflr(p)
	 p.radius=2+flr(rnd(2))
	 p.stype=1+flr(rnd(4))
	 p.amount=4+flr(rnd(4))
	 add(sources,p)
	end
end

function get_closest_source(p)
 local best_d=(planet_radius*2)^2
 local best_i=nil
 for i=1,count(sources) do
  local d=vdist2(p,sources[i])
  if (d<best_d) best_d=d best_i=i
 end
 return {best_i,best_d}
end

function get_resources(p)
 local r={0,0,0,0}
 for i=1,count(sources) do
  local t=get_resource(p,sources[i])
  if t then
   r[t.stype]+=t.amount
  end
 end
 return r
end

function get_resource(p,s)
 local r2=s.radius^2
 local d2=vdist2(p,s)
 if d2<=r2 then
  local t=1-d2/r2
--  print(r2)
--  print(d2)
--  print(t)
  local a=t*s.amount
  return {stype=s.stype,amount=a}
 end
 return nil
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
