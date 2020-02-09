pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--main
function _init()
 planet_center={63.5-30,63.5}
 planet_radius=25
 scanner_pos=vcpy(planet_center)
 sources={}
 signals={}
 for i=1,8 do
  local s={}
	 for i=1,16 do
	  add(s,0)
	 end
	 add(signals,s)
 end
 next_gen_time=0
 next_signal_time=0
 
 generate_sources()
end

function _update60()
 local d={0,0}
 local move=false
 if (btn(⬆️)) d[2]-=1 move=true
 if (btn(⬇️)) d[2]+=1 move=true
 if (btn(⬅️)) d[1]-=1 move=true
 if (btn(➡️)) d[1]+=1 move=true
 
 if move then
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
 
 if btnp(❎) then
  local sp=vcpy(scanner_pos)
  vflr(sp)
  collect_resources(sp)
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
 
 color(7)
 local resources=get_resources(sp)
 print(resources[1])
 print(resources[2])
 print(resources[3])
 print(resources[4])
 
 for i=1,count(sources) do
  print(sources[i].radius)
 end

 pset(scanner_pos[1],scanner_pos[2],8)

 draw_graph(resources)
end

function draw_graph(resources)
 local pos={64,64}
 local len=64
 local resource_len=len/4
 local noise=4
 local signal=signals[1]
 local signals_count=count(signals)
 local n=count(signal)
 local next_signal_delay=0.3
 local signal_y_offset=4

 local t=time()
 if next_gen_time<=t then
  if next_signal_time<=t then
   signal=signals[signals_count]
   for i=signals_count,2,-1 do
    signals[i]=signals[i-1]
   end
   signals[1]=signal
   next_signal_time=t+next_signal_delay
  end
 
  signal[1]=0
  for i=2,n-1 do
   local ri=flr(i/(n/4))+1
   local s=resources[ri]*5
   s+=noise/2-rnd(noise)
   signal[i]=s
  end
  signal[n]=0
  next_gen_time=t+0.1
 end

-- color(7)
-- local p=vcpy(pos)
-- for i=1,n do
--  local x=pos[1]+(i-1)*4
--  local y=pos[2]-signal[i]
--  line(p[1],p[2],x,y)
--  p[1]=x
--  p[2]=y
-- end
 
-- local clrs={7,2,2,2,2,2,2,2,15,14,8}
 local y=pos[2]
 for i=signals_count,2,-1 do
  pos[2]=y-(i-2)*signal_y_offset-(1-(next_signal_time-t)/next_signal_delay)*signal_y_offset
  draw_signal(signals[i],pos,2)
 end
 pos[2]=y
 draw_signal(signals[1],pos,7)
 
-- print(stat(1))
end

function draw_signal(signal,pos,clr)
 color(clr)
 local p=vcpy(pos)
 for i=1,count(signal) do
  local x=pos[1]+(i-1)*4
  local y=pos[2]-signal[i]
  line(p[1],p[2],x,y)
  p[1]=x
  p[2]=y
 end
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
 local min_r=planet_radius/6
 local max_r=planet_radius/4
 srand(0)
	for i=1,5 do
	 local p={rnd(d)-r,rnd(d)-r}
	 vflr(p)
	 local dist=vdist(p,{0,0})
  if r<dist then
   vnorm(p)
	  vscale(p,planet_radius)
	 end
	 vadd(p,planet_center)
	 vflr(p)
	 p.radius=min_r+flr(rnd(max_r-min_r))
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
  local t=(1-sqrt(d2/r2))^2
--  color(10)
--  print(r2)
--  print(d2)
--  print(t)
--  color(7)
  local a=t*s.amount
  return {
   stype=s.stype,
   amount=a,
   distance=sqrt(d2),
   }
 end
 return nil
end

function collect_resources(p)
 local r={0,0,0,0}
 for i=1,count(sources) do
  local t=collect_resource(p,sources[i])
  if t then
   r[t.stype]+=t.amount
  end
 end
 for i=count(sources),1,-1 do
  local elem=sources[i]
  if (elem.amount<=0) del(sources,elem)
 end
 return r
end

function collect_resource(p,s)
 local r=get_resource(p,s)
 if r then
  s.radius=r.distance
  s.amount-=r.amount
 end
 return r
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
