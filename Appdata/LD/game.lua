--BUMP DEMO
--"Once a day, you woke up, and found yourself in a maze with an electronic heart instead of the natural one, then, a robot comes to you and tells you have been put into tests, you have to finish each level to recharge your heart before it runs out of power"

if not SFX then SFX = function() end end
if not Music then Music = function() end end
if not StopAudio then StopAudio = function() end end

local startTime = os.time()
local endTime
local deaths = 0

local sw,sh = screenSize()
local lvlw, lvlh = sw/8, sh/8
local mapW, mapH = TileMap:size()
local cellsize = 8
local debug = false

local omap = {}
local timg = imagedata(mapW*8,mapH*8)
local tquad = timg:quad(0,0,sw,sh)
local tquadX, tquadY = 0, 0
local world
local gameobjs = {}
local tileobjs = {}
local objects = {}
local interactables = {}
local playerobjs = {}

local HP = 4
local HPFFactor = 0.55 --FlickerFactor
local HPFTimer = 3*HPFFactor --FlickerTimer
local HPSpeed = 0.45
local HPColors = {8,9,11,7}

local ThePlayer
local activeSpawner = {2,13,-1}

local function checkbit(flag,n)
  n = n-1
  n = (n==0) and 1 or (2^n)
  return bit.band(flag,n) == n
end

local objtid = {}

local wires = {
  --Level 2
  ["27x15"] = {{25,14}}, --Spawn door
  ["41x14"] = {{32,14},{34,14}}, --Switch Room
  ["33x14"] = {{46,14}}, --Exit door
  --Level 3
  ["51x15"] = {{49,14}}, --Spawn door
  ["53x14"] = {{70,14}}, --Exit door
  --Level 4
  ["75x15"] = {{73,14}}, --Spawn door
  ["88x14"] = {{94,9},{83,13}}, --Clock Switch
  ["94x9"] = {{82,14}}, --Box door
  ["79x14"] = {{94,14}}, --Exit door
  --Level 5
  ["99x15"] = {{97,14}}, --Spawn door
  ["115x15"] = {{118,3},{97,2}}, --Clock 1 switch
  ["118x3"] = {{102,12},{105,12},{108,12},{111,12},{114,12}}, --Doors line 1
  ["97x2"] = {{97,3}},
  ["97x3"] = {{98,3},{112,10}},
  ["98x3"] = {{99,3},{111,10}},
  ["99x3"] = {{100,3},{110,10}},
  ["100x3"] = {{101,3},{109,10}},
  ["101x3"] = {{102,3},{108,10}},
  ["102x3"] = {{103,3},{107,10}},
  ["103x3"] = {{104,3},{106,10}},
  ["104x3"] = {{105,3},{105,10}},
  ["105x3"] = {{106,3},{104,10}},
  ["106x3"] = {{107,3},{103,10}},
  ["107x3"] = {{108,3},{102,10}},
  ["108x3"] = {{109,3},{101,10}},
  ["109x3"] = {{110,3},{100,10}},
  ["110x3"] = {{111,3},{99,10}},
  ["111x3"] = {{112,3},{98,10}},
  ["112x3"] = {{97,2},{112,10},{111,10},{110,10},{109,10},{108,10},{107,10},{106,10},{105,10},{104,10},{103,10},{102,10},{101,10},{100,10},{99,10},{98,10}},
  ["97x11"] = {{117,3}}, --Door lines 3
  ["117x3"] = {{98,5},{100,8},{102,5},{104,8},{106,5},{108,8},{110,5},{112,8},{114,5}},
  ["115x9"] = {{118,14}},--Exit
  --Level 6
  ["123x15"] = {{121,14}}, --Spawn door
  ["130x10"] = {{135,5}}, --Exit door
  ["127x8"] = {{135,5}}, --Exit door :P
  ["125x8"] = {{122,8}}, --Middle door
  --Level 7
  ["125x31"] = {{123,18}}, --The box
  ["131x30"] = {{121,30}}, --The exit
  --Level 8
  ["116x31"] = {{118,30}}, --Spawn Door
  ["100x17"] = {{117,22}}, --
  ["102x17"] = {{117,21}}, --
  ["108x19"] = {{103,21}},
  ["109x19"] = {{117,24}}, --
  ["102x21"] = {{112,30}},
  ["103x21"] = {{108,19}},
  ["111x22"] = {{117,19}}, --
  ["112x22"] = {{117,26}}, --
  ["100x25"] = {{106,26},{102,17}},
  ["106x26"] = {{117,21}}, ---
  ["97x27"] = {{117,23}},  --
  ["111x27"] = {{117,25}}, --
  ["103x28"] = {{117,20}}, --
  ["100x30"] = {{109,19}},
  ["108x30"] = {{100,30}},
  ["109x30"] = {{111,22}},
  ["112x30"] = {{117,18}}, --
  ["117x27"] = {{97,30}}, --Exit
  --Level 9
  ["92x31"] = {{94,30}}, --Spawn Door
  ["89x30"] = {{92,19},{92,24}}, --Enterance
  ["87x19"] = {{87,25}},
  ["87x28"] = {{90,20}},
  ["87x30"] = {{81,22},{82,22},{80,23}}, --Fake
  ["80x19"] = {{84,24}},
  ["82x26"] = {{76,25}},
  ["82x19"] = {{76,29}},
  ["85x30"] = {{74,29}},
  ["80x31"] = {{73,30}}, --Exit
  --Level 10
  ["68x31"] = {{70,30},{53,29},{64,29}}, --Spawn
  ["64x30"] = {{55,29},{62,29}}, --1
  ["62x30"] = {{57,29},{60,29}}, --2
  ["60x30"] = {{49,30}}, --Exit
  --Level 11
  ["44x31"] = {{46,30}}, --Spawn
  ["34x30"] = {{45,18}},
  ["45x27"] = {{42,18}},
  ["42x27"] = {{39,18}},
  ["39x27"] = {{25,30}}, --Exit
  --Level 12
  ["20x31"] = {{22,30}} --End
}

local delays = {
  ["97x2"] = 0.4,
  ["117x3"] = 0.6
}

local msgs = {
  ["2x2"] = "Welcome to the BatteryMan Game !",
  ["2x4"] = [[You are a normal person, who woke
 up to find his heart replaced by
 an electronic one !!

You have to pass all the test to
get back you original heart.]],
  ["2x10"] = "Use arrow keys to move the player",
  
  ["26x4"] = [[Be sure to watch your battery !
That big battery on the ground
will recharge you.
]],
  ["26x9"] = "Press down/x to switch the lever.",
  
  ["50x2"] = "Give yourself some time to\n recharge...",
  ["50x5"] = "Press down to pickup the box,\n press it again to put it back",
  ["50x8"] = "Try not to waste you time !",
  
  ["74x2"] = "This time the door is\n connected to a clock,",
  ["74x4"] = "Switch the lever to activate it.",
  ["74x6"] = "Note: That battery is one time\n use, be wise !",
  ["74x8"] = "Warning ! The door is deadly...",
  
  ["98x2"] = "Note: you can't go down the\n platform after jumping to it.",
  
  ["122x2"] = "I'm done with you,\n solve those levels your own !",
  
  ["50x18"] = [[This is my first Ludum Dare
 Jam game ever, I hope you
 enjoyed it
 
I didn't have enough time to 
 create better levels...

I wounder you died a lot in the
 last 2 levels :P]],
  
  ["26x18"] = [[This game has
been made using
LIKO-12 & Tiled.


Game & Levels By:
@RamiLego4Game

Audio By:
Mikey Fewkes]],
}

------------------------------------------------------------

local function isVisible(obj)
  local x,y = obj.x + obj.w/2, obj.y + obj.h/2
  if x >= tquadX and y >= tquadY and x <= tquadX+sw and y <= tquadY+sh then
    return true
  else
    return false
  end
end

local function outPrint(text,y)
  local tlen = text:len()
  local x = (sw-tlen*5)/2
  rect(x-3,y-3,tlen*5+4,12,false,0)
  color(5)
  print(text,x-1,y)
  print(text,x+1,y)
  print(text,x,y-1)
  print(text,x,y+1)
  color(7)
  print(text,x,y)
end

------------------------------------------------------------

local gameobj = class("gameobj")

function gameobj:initialize(x,y,w,h)
  table.insert(gameobjs,self) --Register this object
  self.x, self.y, self.w, self.h = x or 0,y or 0,w or 0,h or 0
end

function gameobj:draw(dt) end
function gameobj:update(dt) end

------------------------------------------------------------

local animate = {
  frame = 0,
  frames = 1,
  time = 1,
  timer = 0,
  updateAnim = function(self,dt)
    self.timer = self.timer + dt
    if self.timer > self.time/self.frames then
      self.timer = self.timer - self.time/self.frames
      self.frame = self.frame + 1
      self.frame = self.frame % (self.frames-1)
    end
  end
}

------------------------------------------------------------

local velocity = {
  vx = 0,
  vy = 0,
  slowdown = 0,
  updateVelocity = function(self,dt)
    self:move(self.x + self.vx*dt, self.y + self.vy*dt)
    
    --Slowdown
    if self.vx > 0 then
      self.vx = self.vx - self.slowdown*dt
      if self.vx < 0 then self.vx = 0 end
    else
      self.vx = self.vx + self.slowdown*dt
      if self.vx > 0 then self.vx = 0 end
    end
  end
}

------------------------------------------------------------

local gravity = {
  gravity = 32,
  updateGravity = function(self,dt)
    self.vy = self.vy + self.gravity*dt
  end
}

------------------------------------------------------------

local movable = {
  movable = true
}

------------------------------------------------------------

local tileobj = class("tileobj",gameobj)

function tileobj:initialize(sprid,flags,x,y,w,h)
  gameobj.initialize(self)
  table.insert(tileobjs,self)
  self.sprid = sprid or 1
  self.flags = flags or 0
  self.x, self.y = x or 0, y or 0
  self.w, self.h = w or 8, h or 8
  
  self:createBody()
end

function tileobj:createBody(x,y,w,h)
  world:add(self, x or self.x, y or self.y, w or self.w, h or self.h)
end

function tileobj:cache()
  timg:paste(SpriteMap:extract(self.sprid),self.x,self.y)
  self.cached = true
  return self
end

function tileobj:collide(other)
  if checkbit(self.flags,1) then --Up
    if other.y + other.h <= self.y then return "up" end
  end
  if checkbit(self.flags,2) then --Right
    if other.x >= self.x + self.w then return "right" end
  end
  if checkbit(self.flags,3) then --Down
    if other.y >= self.y + self.h then return "down" end
  end
  if checkbit(self.flags,4) then --Left
    if other.x + other.w <= self.x then return "left" end
  end
  return false
end

function tileobj:draw()
  Sprite(self.sprid,self.x,self.y)
end

------------------------------------------------------------

local playerobj = class("playerobj",gameobj)
playerobj:include(animate):include(velocity):include(gravity)

playerobj.static.Player_SprID = 1
playerobj.static.Default_Speed = 64

function playerobj:initialize(sprid,flags,x,y)
  gameobj.initialize(self)
  table.insert(playerobjs,self)
  self.x, self.y = x or 0, y or 0
  self.w, self.h = 6, 7
  self.flags = flags
  
  self.pnum = fget(sprid,1) and 2 or 1
  
  self.frames = 5
  self.time = 0.75
  self.sprid = playerobj.static.Player_SprID
  self.invertX = 1
  
  self.gravity = 180
  self.jump = 120
  self.speed = playerobj.static.Default_Speed
  self.slowdown = self.speed*8
  self.slideSlowdown = self.gravity/2
  
  world:add(self, self.x,self.y, self.w,self.h)
end

function playerobj:filter(other)
    if other.class and other.class == playerobj then
      return false
    elseif other.collide then
      local side, f = other:collide(self)
      if side then
        if side == "down" then
          if self.vy < 0 then self.vy = 0 end
        elseif side ~= "up" then
          self.sliding = btn(1,self.pnum) or btn(2,self.pnum)
        else
          self.hitground = true
        end
        
        if other.bounce then
          self.bounce = other.bounce
          return "bounce"
        else
          return "slide"
        end
      else
        return f
      end
    else
      return "slide"
    end
  end

function playerobj:move(x,y)
  if self.dead then return end
  self.goalX, self.goalY = x, y
  self.x, self.y = world:move(self,x or self.x,y or self.y,self.filter)
  self:updateQuad()
end

function playerobj:updateQuad()
  local quadX, quadY = math.floor((self.x+self.w/2)/sw)*sw, math.floor((self.y+self.h/2)/sh)*sh
  if quadX ~= tquadX or quadY ~= tquadY then
    tquadX, tquadY = quadX, quadY
    tquad:setViewport(tquadX, tquadY, sw, sh)
    cam()
    cam("translate",-tquadX,-tquadY)
  end
end

function playerobj:draw()
  if self.dead then return end
  
  if self.pnum == 1 and debug then
    print("VX: "..self.vx.."\nVY: "..self.vy.."\nOnGround: "..tostring(self.onground),5,5)
  end
  
  if self.pnum == 2 then
    pal(8,12)
    pal(2,1)
  end
  
  local x = self.x
  if self.invertX < 1 then
    x = x + 8
  end
  if self.sliding and not self.killed then
    Sprite(25,x-1,self.y-1,0,self.invertX,1)
  else
    Sprite(self.sprid+self.frame,x-1,self.y-1,0,self.invertX,1)
  end
  
  if self.pnum == 2 then
    pal()
  end
end

function playerobj:isOnGround()
  local function filter(item)
    if item.class and item.class == playerobj then
      return false
    end
    return true
  end
  local items, len = world:queryRect(self.x,self.y+self.h, self.w, 1, filter)
  
  return (len > 0)
end

function playerobj:update(dt)
  if self.dead or self.killed then
    if btnp(7,self.pnum) then
      HP = 4
      HPFTimer = 3*HPFFactor
      
      StopAudio()
      Music(1)
      
      loadMap(true)
      
      self.x, self.y = activeSpawner[1]*8+1, activeSpawner[2]*8+8+1
      self.vx, self.vy = 0, 0
      self.invertX = 1
      self.timer = 0
      self.frame = 0
      
      if self.dead then
        world:add(self,self.x,self.y,self.w,self.h)
      elseif self.killed then
        world:update(self,self.x,self.y,self.w,self.h)
      end
      
      self.dead, self.killed = false, false
      self.hasCrate = false
      
      return
    end
  end
  if self.dead then return end
  if self.killed then
    self.vx = 0
    self:updateGravity(dt)
    self:updateVelocity(dt)
    return
  end
  
  if self.vx ~= 0 and self.onground then
    self:updateAnim(dt)
  else
    self.frame = 0
  end
  
  --Check if on ground
  self.onground = self:isOnGround() and self.hitground
  if not self.onground then self.hitground = false end
  
  --Update controles
  if btn(1,self.pnum) then --Left
    self.invertX = -1
    self.vx = -self.speed
  end
  
  if btn(2,self.pnum) then --Right
    self.invertX = 1
    self.vx = self.speed
  end
  
  if (btn(3,self.pnum) or btn(5,self.pnum)) and self.onground then --Up / Jump
    self.vy = -self.jump
    self.sliding = false
    SFX(3)
  end
  
  if (btnp(3,self.pnum) or btnp(5,self.pnum)) and self.sliding and not self.slideJumped then --Up / Jump
    self.slideJumped = true
    self.vy = -self.jump
    SFX(3)
  end
  
  if self.bounce then
    self.vy = -self.vy*self.bounce
    self.bounce = false
    self.onground = false
  end
  
  if self.onground and self.vy > 0 then self.vy = 0 end
  if self.sliding then
    if self.vy > 0 then
      self.vy = self.vy - self.slideSlowdown*dt
    else
      self.vy = self.vy + self.slideSlowdown*dt
    end
    self.sliding = false
  else
    self.slideJumped = false
  end
  
  self:updateGravity(dt)
  self:updateVelocity(dt)
  
  self.interactPress = false
  if btn(4,self.pnum) or btn(6,self.pnum) then --Down (Interact)
    self.interactPress = btnp(4,self.pnum) or btnp(6,self.pnum)
    for k, obj in ipairs(interactables) do
      obj:interact(self,self.interactPress)
    end
  else
    self.interact = true
  end
end

function playerobj:kill()
  if not self.dead then
    self.killed = true -- RIP q-q
    self.frame = 5
  end
  Music(1,true)
  SFX(11)
  deaths = deaths + 1
end

function playerobj:remove()
  self.dead = true -- DIE
  world:remove(self)
  HP = 0
end

------------------------------------------------------------

local objectbase = class("objectbase",gameobj)

function objectbase:initialize(sprid,flags,x,y,w,h)
  gameobj.initialize(self)
  table.insert(objects,self)
  self.sprid = sprid or 1
  self.origSprID = self.sprid
  self.flags = flags or 0
  self.x, self.y = x or 0, y or 0
  self.w, self.h = w or 8, h or 8
  self.ox, self.oy = 0, 0 --Drawing offset
  self.tx, self.ty = self.x/8, self.y/8
  self.wireid = self.tx.."x"..self.ty
  
  self.state = false --The wire state
end

function objectbase:createBody()
  world:add(self,self.x,self.y,self.w,self.h)
  self.hasBody = true
end

function objectbase:collide(other)
  if other.y + other.h <= self.y then return "up" end
  if other.x >= self.x + self.w then return "right" end
  if other.y >= self.y + self.h then return "down" end
  if other.x + other.w <= self.x then return "left" end
  return false
end

function objectbase:draw()
  if self.dead then return end
  Sprite(self.sprid,self.x+self.ox,self.y+self.oy)
end

function objectbase:switch(state)
  if self.dead then return end
  if type(state) == "nil" then
    self.state = not self.state
  else
    self.state = state
  end
end

function objectbase:trigger(state)
  if self.dead then return end
  if wires[self.wireid] then
    for k,v in ipairs(wires[self.wireid]) do
      if omap[v[1]][v[2]] then
        omap[v[1]][v[2]]:switch(state)
      end
    end
  end
end

function objectbase:interact(player,p) end --Called when a player press the down button
function objectbase:enableInteract() --Register the object for interacting
  table.insert(interactables,self)
end

function objectbase:remove()
  if self.dead then return end
  if self.hasBody then
    world:remove(self)
  end
  self.dead = true
end

objtid[0] = objectbase

------------------------------------------------------------

local switchObj = class("switchObj",objectbase)

function switchObj:initialize(sprid,flags,x,y,w,h)
  objectbase.initialize(self,sprid,flags,x,y,w,h)
  self:enableInteract()
  if self.sprid % 2 == 0 then self.state = true; self.sprid = self.sprid-1; self:trigger(self.state) end
  
  self.playerFilter = function(item)
    if not self.player then return end
    return self.player == item
  end
end

function switchObj:draw()
  if self.state then
    Sprite(self.sprid+1,self.x,self.y)
  else
    Sprite(self.sprid,self.x,self.y)
  end
end

function switchObj:interact(player,press)
  if not press then return end
  self.player = player
  local players = world:queryRect(self.x, self.y, self.w, self.h, self.playerFilter)
  if #players > 0 then
    self.state = not self.state
    self:trigger()
  end
end

objtid[1] = switchObj

------------------------------------------------------------

local vdoorObj = class("vdoorObj",objectbase)

function vdoorObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  self.x = self.x+1
  self.w = self.w-2
  self.ox = -1
  
  if self.sprid % 2 == 0 then self.state = true; self.sprid = self.sprid-1 end
  if self.sprid < 73 then self.killer = true end
  
  self:createBody()
  
  self.playerFilter = function(item)
    return item:isInstanceOf(playerobj)
  end
end

function vdoorObj:collide(other)
  if other.y + other.h <= self.y then return "up" end
  if other.x >= self.x + self.w and not self.state then return "right" end
  if other.y >= self.y + self.h then return "down" end
  if other.x + other.w <= self.x and not self.state then return "left" end
  return false
end

function vdoorObj:draw()
  if self.state then
    Sprite(self.sprid+1,self.x+self.ox,self.y+self.oy)
  else
    Sprite(self.sprid,self.x+self.ox,self.y+self.oy)
  end
end

function vdoorObj:switch(state)
  objectbase.switch(self,state)
  if not self.state then
    if isVisible(self) then SFX(1) end
    local players = world:queryRect(self.x,self.y, self.w,self.h, self.playerFilter)
    for k, player in ipairs(players) do
      player:remove()
      if not self.killer then self.sprid = self.sprid - 24 end
      self.killer = true
    end
  else
    if isVisible(self) then SFX(2) end
  end
end

objtid[2] = vdoorObj

------------------------------------------------------------

local batteryObj = class("batteryObj",objectbase)

function batteryObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  self.y = self.y+2
  self.h = self.h-4
  self.oy = -2
  self.charge = tileid - 25 + 0.5
  
  self:createBody()
end

function batteryObj:collide(obj)
  if self.kill then return end
  if obj:isInstanceOf(playerobj) then
    HP = math.floor(math.min(4,HP+self.charge))
    HPFTimer = math.min(HP,3)*HPFFactor
    SFX(4)
    self.kill = true
  end
  
  return false
end

function batteryObj:update(dt)
  if self.dead then return end
  if self.kill then self:remove() end
end

function batteryObj:remove()
  if self.dead then return end
  self.dead = true
  world:remove(self)
end

objtid[3] = batteryObj

------------------------------------------------------------

local crateObj = class("crateObj",objectbase)
crateObj:include(velocity):include(gravity):include(movable)

function crateObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  self.y = self.y-1
  self.x = self.x+1
  self.w, self.h = self.w-2, self.h-2
  self.oy = -2
  
  self.gravity = 180
  self.slowdown = 20
  
  self:enableInteract()
  self:createBody()
  
  self.playerFilter = function(item)
    if not self.player then return end
    return item == self.player
  end
  
  self.spawnFilter = function(item)
    if not self.player then return true end
    return (not (item == self.player))
  end
end

function crateObj:filter(item)
  if item.collide then
    local side, f = item:collide(self)
    if side then
      if side == "up" then if self.vy > 0 then self.vy = 0 end
      elseif side ~= "down" then self.vx = 0 end
      return "slide"
    else
      return f
    end
  else
    return "slide"
  end
end

function crateObj:move(x,y)
  if self.dead then return end
  self.x,self.y = world:move(self,x,y,self.filter)
end

function crateObj:update(dt)
  if self.dead then return end
  self:updateGravity(dt)
  self:updateVelocity(dt)
end

function crateObj:interact(player,p)
  if not p then return end
  if player.hasCrate then
    if player.hasCrate == self then
      --Check if there's space under the player
      local objects = world:queryRect(player.x,player.y+player.h,self.w,self.h,self.spawnFilter)
      if #objects == 0 then
        self.x, self.y = player.x, player.y + player.h
        self.vx, self.vy = player.vx, player.vy
        self.dead = false
        world:add(self,self.x,self.y,self.w,self.h)
        player.hasCrate = nil
        SFX(8)
        return
      end
      
      --Check if we can push the player to up
      local objects = world:queryRect(player.x,player.y-self.h,player.w,player.h,self.spawnFilter)
      if #objects == 0 then
        player:move(player.x,player.y-self.h)
        self.x, self.y = player.x, player.y + player.h
        self.vx, self.vy = player.vx, player.vy
        self.dead = false
        world:add(self,self.x,self.y,self.w,self.h)
        player.hasCrate = nil
        SFX(8)
        return
      end
    end
  else
    self.player = player
    local players = world:queryRect(self.x,self.y-1,self.w,1,self.playerFilter)
    if #players > 0 then
      player.hasCrate = self
      self:remove()
      player:move(player.x,player.y+self.h)
      SFX(4)
    end
  end
end

function crateObj:remove()
  if self.dead then return end
  self.dead = true
  world:remove(self)
end

objtid[4] = crateObj

------------------------------------------------------------

local gbuttonObj = class("gbuttonObj",objectbase)

function gbuttonObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  
  self:createBody()
  
  self.filter = function(item)
    return (item ~= self)
  end
end

function gbuttonObj:draw()
  objectbase.draw(self)
  if self.state then
    Sprite(8,self.x, self.y-8)
  else
    Sprite(7,self.x, self.y-8)
  end
end

function gbuttonObj:update(dt)
  if not self.state then
    local objects = world:queryRect(self.x+2,self.y-2,self.w-4,2,self.filter)
    if #objects > 0 then
      self.state = true
      self.sprid = self.sprid + 1
      self:trigger()
    end
  end
end

objtid[5] = gbuttonObj

------------------------------------------------------------

local tbatteryObj = class("tbatteryObj",objectbase)

function tbatteryObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  
  self.charge = 2.5
  self.dt = 0
  
  self:createBody()
end

function tbatteryObj:draw()
  if self.dead then return end
  SpriteGroup(self.sprid-24,self.x+self.ox, self.y+self.oy-8,1,2)
end

function tbatteryObj:collide(item)
  local c, f = objectbase.collide(self,item)
  if c then
    if item:isInstanceOf(playerobj) and HP > 0 then
      HP = math.min(HP+self.charge*self.dt,4) --Fill the HP
      HPFTimer = math.min(HP,3)*HPFFactor
    end
  end
  return c,f
end

function tbatteryObj:update(dt)
  self.dt = dt
end

objtid[6] = tbatteryObj

------------------------------------------------------------

local pbuttonObj = class("pbuttonObj",objectbase)

function pbuttonObj:update(dt)
  local objects = world:queryRect(self.x+1,self.y+6,self.w-2,2)
  if #objects > 0 and not self.state then
    self.state = true
    self.sprid = self.sprid + 1
    self:trigger(self.state)
  elseif #objects == 0 and self.state then
    self.state = false
    self.sprid = self.sprid - 1
    self:trigger(self.state)
  end
end

objtid[7] = pbuttonObj

------------------------------------------------------------

local clockObj = class("clockObj",objectbase)

function clockObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  self.state = true
  self.time = self.sprid - 96
  
  if self.time > 24 then
    self.time = self.time - 24
    self.state = false
  end
  
  if delays[self.wireid] then self.time = delays[self.wireid] end
  
  self.timer = self.time
end

function clockObj:draw()
  --Nothing :P
end

function clockObj:update(dt)
  if self.state then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      self:trigger()
      self.timer = self.time
    end
  end
end

function clockObj:switch(state)
  objectbase.switch(self,state)
  self.timer = 0
end

objtid[8] = clockObj

------------------------------------------------------------

local bulbObj = class("bulbObj",objectbase)

function bulbObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  
  if self.sprid % 2 == 0 then
    self.sprid = self.sprid - 1
    self.state = true
  end
end

function bulbObj:draw()
  if self.state then
    Sprite(self.sprid+1, self.x,self.y)
  else
    Sprite(self.sprid, self.x,self.y)
  end
end

objtid[9] = bulbObj

------------------------------------------------------------

local msgObj = class("msgObj",objectbase)

function msgObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  self.color = self.sprid-145
  if msgs[self.wireid] then
    self.msg = msgs[self.wireid]
  end
end

function msgObj:draw()
  if self.msg then
    color(self.color)
    print(self.msg,self.x, self.y)
  end
end

objtid[10] = msgObj

------------------------------------------------------------

local delayObj = class("delayObj",objectbase)

function delayObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  self.state = true
  self.time = self.sprid - 168
  if self.sprid == 168 then self.time = 0.15 end
  if delays[self.wireid] then self.time = delays[self.wireid] end
  
  self.timer = -1
end

function delayObj:draw()
  --Nothing :P
end

function delayObj:update(dt)
  if self.timer > 0 then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      self:trigger(self.state)
    end
  end
end

function delayObj:switch(state)
  self.state = state
  self.timer = self.time
end

objtid[11] = delayObj

------------------------------------------------------------

local spawnObj = class("spawnObj",objectbase)

function spawnObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  
  self:createBody()
  self.id = #objects
  
  self.filter = function(item)
    return item:isInstanceOf(playerobj)
  end
end

function spawnObj:draw()
  if activeSpawner[3] == self.id then
    Sprite(self.sprid+1,self.x,self.y)
  else
    Sprite(self.sprid,self.x,self.y)
  end
end

function spawnObj:update(dt)
  if activeSpawner[3] ~= self.id then
    local players = world:queryRect(self.x,self.y+self.h,8,8,self.filter)
    if players[1] then
      activeSpawner = {self.x/8,self.y/8,self.id}
    end
  end
end

objtid[12] = spawnObj

------------------------------------------------------------

local trapdoorObj = class("trapdoorObj",objectbase)

function trapdoorObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  self.h = 2
  
  if self.sprid % 2 == 1 then self.state = true; self.sprid = self.sprid-1 end
  
  self:createBody()
end

function trapdoorObj:collide(other)
  if other.y + other.h <= self.y and not self.state then return "up" end
  if other.x >= self.x + self.w then return "right" end
  if other.y >= self.y + self.h and not self.state then return "down" end
  if other.x + other.w <= self.x then return "left" end
  return false
end

function trapdoorObj:draw()
  if self.state then
    Sprite(self.sprid+1,self.x+self.ox,self.y+self.oy)
  else
    Sprite(self.sprid,self.x+self.ox,self.y+self.oy)
  end
end

function trapdoorObj:switch(state)
  objectbase.switch(self,state)
  if not self.state then
    if isVisible(self) then SFX(1) end
  else
    if isVisible(self) then SFX(2) end
  end
end

objtid[13] = trapdoorObj

------------------------------------------------------------

local beltObj = class("beltObj",objectbase)

function beltObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  
  self.frame = 0
  self.frames = 4
  self.time = 0.2
  self.timer = 0
  
  self.left = (self.sprid == 56)
  self.speed = self.time*100
  self.maxs = self.speed * 2
  
  if self.left then self.speed = -self.speed end
  
  self:createBody()
end

function beltObj:collide(item)
  local c, f = objectbase.collide(self,item)
  if c and item.vx then
    if c == "left" and math.abs(item.vy) > self.maxs then
      item.vy = item.vy - self.speed
    elseif c == "right" and math.abs(item.vy) < self.maxs then
      item.vy = item.vy + self.speed
    elseif c == "up" and math.abs(item.vx) < self.maxs then
      item.vx = item.vx + self.speed
    elseif c == "down" and math.abs(item.vx) > self.maxs then
      item.vx = item.vx - self.speed
    end
  end
  
  return c, f
end

function beltObj:draw()
  if self.dead then return end
  Sprite(self.sprid+self.frame,self.x,self.y)
end

function beltObj:update(dt)
  if self.dead then return end
  self.timer = self.timer + dt
  if self.timer >= self.time then
    self.timer = 0
    if self.left then
      self.frame = self.frame - 1
      if self.frame <= -self.frames then self.frame = 0 end
    else
      self.frame = self.frame + 1
      if self.frame >= self.frames then self.frame = 0 end
    end
  end
end

objtid[14] = beltObj

------------------------------------------------------------

local heartObj = class("heartObj",objectbase)

function heartObj:initialize(tileid,flags,x,y,w,h)
  objectbase.initialize(self,tileid,flags,x,y,w,h)
  self.w, self.h = 16,16
  
  self.filter = function(item)
    return item:isInstanceOf(playerobj)
  end
end

function heartObj:draw()
  if self.dead then
    --Draw Score
    local rw, rh = 120, 86
    local rx, ry = (sw-rw)/2, (sh-rh)/2
    pushMatrix() cam()
    cam("translate",rx,ry)
    rect(0,0,rw,rh,false,0)
    rect(0,0,rw,rh,true,7)
    
    color(11)
    print("-==BatteryMan LD39==-",8,4)
    
    color(7)
    print("- Time: "..os.date("%M:%S",endTime-startTime),4,18)
    
    color(6)
    print("- Deaths: "..deaths,4,26)
    
    color(7)
    print("- Score: "..(9999-(deaths*100 + (endTime-startTime)*10))*10,4,34)
    
    color(9)
    print("Press escape/back twice\n to quit",3,46)
    
    color(12)
    print("Game by @RamiLego4Game\nAudio by Mikey Fewkes",4, rh-18)
    
    popMatrix()
    return
  end
  SpriteGroup(self.sprid,self.x,self.y,2,2)
end

function heartObj:update(dt)
  if self.dead then return end
  local players = world:queryRect(self.x,self.y,self.w,self.h,self.filter)
  if #players > 0 then
    self.dead  = true
    StopAudio()
    SFX(10)
    HP = 5
    endTime = os.time()
  end
end

objtid[15] = heartObj

------------------------------------------------------------

function loadMap(reload)
  if reload then
    interactables = {}
    for k, obj in ipairs(objects) do
      obj:remove()
    end
    objects = {}
  end
  
  omap = {}
  
  for x=0,mapW-1 do
    omap[x] = {}
    for y=0, mapH-1 do
      omap[x][y] = false
    end
  end
  
  TileMap:map(function(x,y,tileid)
    if tileid == 0 then return end
    local flags = fget(tileid)
    local tiletype = bit.rshift(flags,6)
    
    if tiletype == 0 and not reload then --Static Tile
      local tobj = tileobj:new(tileid,flags,x*8,y*8):cache()
    elseif tiletype == 1 and not reload then --Bouncy
      local tobj = tileobj:new(tileid,flags,x*8,y*8):cache()
      tobj.bounce = 0.92
    elseif tiletype == 2 and not reload then --Player
      ThePlayer = playerobj:new(tileid,flags,x*8,y*8)
    elseif tiletype == 3 then --Object
      local objid = bit.band(flags,0x3F)
      if objtid[objid] then
        omap[x][y] = objtid[objid](tileid,flags,x*8,y*8)
      else
        error("Unknown object ["..objid.."] at "..x..", "..y)
      end
    end
  end)
  
  if not reload then timg = timg:image() end
end

local function drawHP()
  pal(1,0)
  if HP <= 0 then
    SpriteGroup(12,sw-16-8-2,8+4+-4,2,2)
  else
    if HPFTimer <= 0 then return end
    local hpcolor = HPColors[math.ceil(HP)]
    
    for i=1,4 do
      if i <= math.ceil(HP) then
        pal(11+i,hpcolor)
      else
        pal(11+i,0)
      end
    end
    SpriteGroup(10,sw-16-8-2,8+4,2,1)
  end
  pal()
end

------------------------------------------------------------

function _init()
  world = bump.newWorld(cellsize)
  clearEStack()
  loadMap()
  Music(1)
end

function _draw(dt)
  --Draw background
  clear(0)
  
  --Draw tiles
  pushMatrix() cam()
  timg:draw(0,0,0,1,1,tquad)
  popMatrix()
  
  --Draw players
  for id, player in ipairs(playerobjs) do
    player:draw(dt)
  end
  
  --Draw objects
  for id, obj in ipairs(objects) do
    obj:draw(dt)
  end
  
  --HUD
  pushMatrix() cam()
  if HP <= 4 then drawHP() end
  
  if HP < 0 then
    outPrint("Press Start to respawn",sh/2)
  end
  
  popMatrix()
end

function _update(dt)
  --Update players
  for id, player in ipairs(playerobjs) do
    player:update(dt)
  end
  
  --Draw objects
  for id, obj in ipairs(objects) do
    obj:update(dt)
  end
  
  --Update HP
  if HP > 0 and HP <= 4 then
    HP = math.max(HP - HPSpeed*dt,0)
  end
  
  if HP <= 3 and HP > 0 then
    HPFTimer = HPFTimer - dt
    if HPFTimer < -HP*HPFFactor/2 then
      HPFTimer = HP*HPFFactor
      SFX(5)
    end
  elseif HP == 0 then
    HP = -1
    for k, player in ipairs(playerobjs) do
      if not player.killed then player:kill() end
    end
  end
end