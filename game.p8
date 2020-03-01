pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--main
function _init()
 planet_center={63.5-30,63.5}
 planet_radius=25
 scanner_pos_offset=vcpy(planet_center)
 scanner_pos=vcpy(scanner_pos_offset)
 signal=init_signal()
 planet_offset=0

 planet=generate_planet_view(planet_center,planet_radius)
 surface=init_planet_surface()
 sources=generate_sources(surface.pos[1],surface.pos[2],surface.size[1],surface.size[2])
end

function _update60()
 local d={0,0}
 local move=false

 if btn(⬆️) then
  d[2]-=1 move=true
 elseif btn(⬇️) then
  d[2]+=1 move=true
 end

 if btn(⬅️) then
  d[1]-=1 move=true
 elseif btn(➡️) then
  d[1]+=1 move=true
 end

 if move then
  vnorm(d)
  vscale(d,0.3)
  vadd(scanner_pos,d)
  if (surface.size[1]<=scanner_pos[1]) planet_offset-=surface.size[1]
  if (scanner_pos[1]<0) planet_offset+=surface.size[1]
  scanner_pos[1]=scanner_pos[1]%surface.size[1]
  scanner_pos[2]=clamp(scanner_pos[2],32+8,63+32-8)
 end

 if btnp(❎) then
  local sp=vcpy(scanner_pos)
  vflr(sp)
  sources.collect(sp)
 end

 local border=16
 local d=scanner_pos[1]-scanner_pos_offset[1]-planet_offset
 if (d<-border) planet_offset+=d+border
 if (border<d) planet_offset+=d-border
end

function _draw()
 local sp=vcpy(scanner_pos)
 vflr(sp)

-- cls()

 surface.draw(scanner_pos,planet_offset)
-- if (true) return
 planet.draw(planet_offset,surface.get_pixel)
-- if (true) color(11) print(stat(0)..' '..stat(1)) return

-- pset(planet_center[1],planet_center[2],7)
 circ(planet_center[1],planet_center[2],planet_radius+1,7)


 sources.draw(sp)
 sources.debug_print(sp)

 pset(scanner_pos[1],scanner_pos[2],8)

 local resources=sources.get_resources(sp)
 signal.draw(resources)

 color(11) print(stat(0)..' '..stat(1))
end
-->8
--math
function clamp(v,v_min,v_max)
 return min(max(v,v_min),v_max)
end

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
function generate_sources(x,y,w,h)
 local sources={}
 local min_r=planet_radius/6
 local max_r=planet_radius/4
 srand(0)
 for i=1,5 do
  local p={rnd(w)+x,rnd(h)+y}
  vflr(p)
  p.radius=min_r+flr(rnd(max_r-min_r))
  p.stype=1+flr(rnd(4))
  p.amount=4+flr(rnd(4))
  add(sources,p)
 end

 local function get_closest_source(p)
  local best_d=(planet_radius*2)^2
  local best_i=nil
  for i=1,#sources do
   local d=vdist2(p,sources[i])
   if (d<best_d) best_d=d best_i=i
  end
  return {best_i,best_d}
 end

 local function get_resource(p,s)
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

 local function get_resources(p)
  local r={0,0,0,0}
  for i=1,#sources do
   local t=get_resource(p,sources[i])
   if t then
    r[t.stype]+=t.amount
   end
  end
  return r
 end

 local function collect_resource(p,s)
  local r=get_resource(p,s)
  if r then
   s.radius=r.distance
   s.amount-=r.amount
  end
  return r
 end

 local function collect_resources(p)
  local r={0,0,0,0}
  for i=1,#sources do
   local t=collect_resource(p,sources[i])
   if t then
    r[t.stype]+=t.amount
   end
  end
  for i=#sources,1,-1 do
   local elem=sources[i]
   if (elem.amount<=0) del(sources,elem)
  end
  return r
 end

 return {
  get_resources=get_resources,
  collect=collect_resources,
  draw=function(position)
   local best_i=get_closest_source(position)
   for i=1,#sources do
    local c=best_i[1]==i and 9 or 3
    pset(sources[i][1],sources[i][2],c)
   end
  end,
  debug_print=function(position)
   color(7)
   local resources=get_resources(position)
   print(resources[1])
   print(resources[2])
   print(resources[3])
   print(resources[4])

   for i=1,#sources do
    print(sources[i].radius)
   end
  end,
  }
end
-->8
--planet view
function generate_planet_view(center,radius)

 local tilt=0.15
 local pryy,pryz,przy,przz=
  cos(tilt),sin(tilt),
  -sin(tilt),cos(tilt)
 local center_x,center_y=center[1],center[2]

 function round(x)
  return flr(x+0.5)
 end

 local function asin(x)
  local negate=(x<0 and 1.0 or 0.0)
  x=abs(x)
  local r=((-0.0187293*x+0.0742610)*x-0.2121144)*x+1.5707288
  r=3.14159265358979*0.5-sqrt(1.0-x)*r
  return r-2*negate*r
 end

 local function get_addr(x,y,base)
  return flr(base+(x+y*128)*0.5)
 end

 local function project(x,y,z)
  local py,pz=
   pryy*y+przy*z,
   pryz*y+przz*z
  return center_x+x,center_y+py,pz
 end

 local function prep_planet()
  local points={}
  local size=radius
  -- texture coords
  local tox,toy,tw,th=
   64,0,128,64
  local tcy=toy+th/2
  for lat=-0.25,0.25,0.003 do
   local scl=cos(lat)
   local sscl=size*scl
   for long=-0.5,0.5,0.003/scl do
    -- 3d
    local x,z,y=
     sscl*cos(long),
     sscl*sin(long),
     size*sin(lat)
    -- 2d
    local fx,fy,fz=
     project(x,y,z)
    fx,fy=round(fx),round(fy)
    -- texture
    local tx,ty=
     flr(tox+long*tw%tw),
     flr(tcy-lat*2*th)
    if 0<fz then
     if not points[fy] then
      points[fy]={}
     end
     points[fy][fx]={tx,ty}
    end
   end
  end
  return points
 end

 local left=center[1]-radius
 local right=center[1]+radius
 local top=center[2]-radius
 local bottom=center[2]+radius
 local diameter=radius*2
 local height=64

 left=flr(left)
 right=flr(right)
 top=flr(top)
 bottom=flr(bottom)

 local points=prep_planet()
 local function draw_planet(offset,get_pixel)
  for y,pp in pairs(points) do
   for x,uv in pairs(pp) do
    local c=get_pixel(uv[1],uv[2])
    pset(x,y,c)
   end
  end
 end

 return {draw=draw_planet}
end


-->8
--signal
function init_signal()
 local signals={}
 for i=1,8 do
  local s={}
  for i=1,16 do
   add(s,0)
  end
  add(signals,s)
 end
 local next_gen_time=0
 local next_signal_time=0

 local function draw_signal(signal,pos,clr)
  color(clr)
  local p=vcpy(pos)
  for i=1,#signal do
   local x=pos[1]+(i-1)*4
   local y=pos[2]-signal[i]
   line(p[1],p[2],x,y)
   p[1]=x
   p[2]=y
  end
 end

 local function draw_graph(resources)
  local pos={64,64}
  local len=64
  local resource_len=len/4
  local noise=4
  local signal=signals[1]
  local signals_count=#signals
  local n=#signal
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

   if i==signals_count-1 then
    for x=pos[1],pos[1]+(#signals[i]-1)*4,4 do
     line(x,4,x,50,0)
    end
   elseif i==signals_count-3 then
    for x=pos[1]+2,pos[1]+(#signals[i]-1)*4,4 do
     line(x,4,x,50,0)
    end
   end
  end
  pos[2]=y
  draw_signal(signals[1],pos,7)
 end

 return {draw=draw_graph}
end
-->8
--planet surface
function init_planet_surface()
 cls()

 local position={0,32}
 local size={128,64}

 for y=0,size[2]-1 do
  for x=0,size[1]-1 do
   local c=(flr(x/4)+flr(y/4))%2==0 and 6 or 14
   pset(x,y,c)
  end
 end
 memcpy(0x1000,0x6000,1024*4)

 local function draw_target(x,y)
  sspr(8,0,16,16,x-8,y-8)
 end

 return {
  pos=position,
  size=size,
  draw=function(p,offset)
   cls()
   offset=offset%128
   local flroff=flr(offset)
   if flroff==0 then
    sspr(flroff,64,128,64,0,32)
   else
    sspr(flroff,64,128-flroff,64,0,         32)
    sspr(0,     64,flroff,    64,128-flroff,32)
   end
   draw_target(p[1]-offset,p[2])
   draw_target(p[1]-offset+128,p[2])
   memcpy(0x2000,0x6000+1024*2,1024*4)
   cls()
  end,
  get_pixel=function(x,y)
   local c=peek(0x2000+(x+y*128)*0.5)
   if (x%2~=0) c=shr(c,4)
   c=band(c,0xf)
   return c
  end,
 }
end
__gfx__
00000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000008800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000888800888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000880088008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700008800088000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008800000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000880088088088008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000880088088088008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008800000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008800088000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000880088008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000888800888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000008800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
