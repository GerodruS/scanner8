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

 function v3d(x,y,z)
  return {x=x,y=y,z=z}
 end

 function v3ddot(grad,x,y,z)
  return grad.x*x+grad.y*y+grad.z*z
 end

 grad3={
   [0]=v3d(1,1,0),v3d(-1,1,0),v3d(1,-1,0),v3d(-1,-1,0),
   v3d(1,0,1),v3d(-1,0,1),v3d(1,0,-1),v3d(-1,0,-1),
   v3d(0,1,1),v3d(0,-1,1),v3d(0,1,-1),v3d(0,-1,-1)
 }

 ps={[0]=151,160,137,91,90,15,
 131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
 190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
 88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
 77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
 102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
 135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
 5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
 223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
 129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
 251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
 49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
 138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180}
 local perm,perm12={},{}
 for i=0,511 do
  perm[i]=ps[band(i,0xff)]
  perm12[i]=perm[i]%12
 end

 local skew,unskew=1/3,1/6
 local unskew2,unskew3=2*unskew,3*unskew

 -- the main noise generator function
 function simplex3d(x,y,z)
  local n0,n1,n2,n3
  local s=(x+y+z)*skew
  local i,j,k=
   flr(x+s),flr(y+s),flr(z+s)
  local t=(i+j+k)*unskew
  local xo,yo,zo=i-t,j-t,k-t
  local xd,yd,zd=x-xo,y-yo,z-zo

  local i1,j1,k1,i2,j2,k2
  if xd>=yd then
   if yd>=zd then
    i1,j1,k1,i2,j2,k2=
     1,0,0,1,1,0
   elseif xd>=zd then
    i1,j1,k1,i2,j2,k2=
     1,0,0,1,0,1
   else
    i1,j1,k1,i2,j2,k2=
     0,0,1,1,0,1
   end
  else
   if yd<zd then
    i1,j1,k1,i2,j2,k2=
     0,0,1,0,1,1
   elseif xd<zd then
    i1,j1,k1,i2,j2,k2=
     0,1,0,0,1,1
   else
    i1,j1,k1,i2,j2,k2=
     0,1,0,1,1,0
   end
  end

  local x1,y1,z1=
   xd-i1+unskew,
   yd-j1+unskew,
   zd-k1+unskew
  local x2,y2,z2=
   xd-i2+unskew2,
   yd-j2+unskew2,
   zd-k2+unskew2
  local x3,y3,z3=
   xd-1+unskew3,
   yd-1+unskew3,
   zd-1+unskew3
  local ii,jj,kk=
   band(i,0xff),band(j,0xff),band(k,0xff)
  local gi0,gi1,gi2,gi3=
   perm12[ii+perm[jj+perm[kk]]],
   perm12[ii+i1+perm[jj+j1+perm[kk+k1]]],
   perm12[ii+i2+perm[jj+j2+perm[kk+k2]]],
   perm12[ii+1+perm[jj+1+perm[kk+1]]]
  local t0=0.6-xd*xd-yd*yd-zd*zd
  if t0<0 then
   n0=0
  else
   t0*=t0
   n0=t0*t0*v3ddot(grad3[gi0],xd,yd,zd)
  end
  local t1=0.6-x1*x1-y1*y1-z1*z1
  if t1<0 then
   n1=0
  else
   t1*=t1
   n1=t1*t1*v3ddot(grad3[gi1],x1,y1,z1)
  end
  local t2=0.6-x2*x2-y2*y2-z2*z2
  if t2<0 then
   n2=0
  else
   t2*=t2
   n2=t2*t2*v3ddot(grad3[gi2],x2,y2,z2)
  end
  local t3=0.6-x3*x3-y3*y3-z3*z3
  if t3<0 then
   n3=0
  else
   t3*=t3
   n3=t3*t3*v3ddot(grad3[gi3],x3,y3,z3)
  end
  return 32*(n0+n1+n2+n3)
 end

 function noisegen(seed,scale_x,octaves,scale_y)
  if (not scale_y) scale_y=scale_x
  local base_m=
   2^(octaves-1)/(2^octaves-1)
  return function(x,y,z)
   local n,m,sx,sy=
    0,base_m,scale_x,scale_y
   for o=1,octaves do
    n+=m*simplex3d(x*sx,y*sy,z*sx+seed)
    sx,sy,m=
     shl(sx,1),shl(sy,1),shr(m,1)
   end
   return n
  end
 end

 function noise(...)
  local ng=noisegen(...)
  return function(tx,ty)
   local lng,lat=
    tx/128,(ty-31.5)/126
   local y,scl=-sin(lat),cos(lat)
   local x,z=scl*sin(lng),scl*cos(lng)
   return ng(x,y,z)
  end
 end

 local n=noise(0,3,1,3)

 function evaluate(x,y)
  return n(x,y)
 end

 local position={0,32}
 local size={128,64}
 local colors={7,6,5,2}

 for y=0,size[2]-1 do
  for x=0,size[1]-1 do
   local v=(evaluate(x,y)+1)/2
   local c=colors[flr(v*#colors)+1]
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
