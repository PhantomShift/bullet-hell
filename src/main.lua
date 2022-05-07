love.window.setMode(350, 800, {vsync=false})
love.window.setTitle(":MatsuriDerp:")

local player = require "player"
local enemy = require "enemy"
local Vector2 = require "Vector2"
local camera = require "camera"
local geometry = require "geometry"
local Shapes = geometry.Shapes
local projectile = require "projectile"
local taskscheduler = require "taskscheduler"
local BindableEvent = require "BindableEvent"
local path = require "path"
local Interface = require "Interface"
local UserInput = require "UserInput"
local statemanager = require "statemanager"

table.unpack = unpack

local GameEnded = BindableEvent.new()

local main_thread = taskscheduler.schedulers.main

local delayedExecute = main_thread.delay

local GameWon = BindableEvent.new()
GameWon:Connect(function()
    local win_text = love.graphics.newText(love.graphics.getFont(), "YOU WIN!")
    function love.update()

    end
    function love.draw()
        love.graphics.setColor(0,0,0)
        love.graphics.draw(win_text, X_MAX / 2, Y_MAX / 2, 0, 2, 2, win_text:getWidth()/2, win_text:getHeight()/2)
    end
end)

function clear_list(list)
    for key, _ in pairs(list) do
        list[key] = nil
    end
end

math.randomseed(os.time())
-- initialization
local initial_load = true
function love.load()
    clear_list(projectile.ProjectileList)
    ProjectileList = projectile.ProjectileList
    physics_objects = {}
    GRAVITY = -9.81 * 10
    -- grab window size
    Y_MAX = love.graphics.getHeight()
    X_MAX = love.graphics.getWidth()

    -- player.pos = Vector2.new(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    
    PAUSED = false
    function togglePause()
        PAUSED = not PAUSED
        main_thread.Paused = PAUSED
    end
    ACTIVE = true
    local regular_font = love.graphics.getFont()
    GAME_OVER = love.graphics.newText(regular_font, "GAME OVER!")
    PAUSED_TEXT = love.graphics.newText(regular_font, "PAUSED")

    enemy:clearEnemyList()
    enemy_list = enemy.__enemy_list
    -- Temporary AI lol
    function aimedFireLaser(currentPos, targetPos, delay, flags)
        local info = {
            draw = function(self)
                local r,g,b,a = love.graphics.getColor()
                love.graphics.setColor(0, 0, 1, delay - self.time)
                local c = currentPos
                local aim = c + (targetPos - c).Unit * 10000
                love.graphics.line(c.x, c.y, aim.x, aim.y)
                love.graphics.setColor(r,g,b,a)
            end,
            update = function(self, elapsedTime) self.time = self.time + elapsedTime end,
            hits = function() end,
            time = 0
        }
        ProjectileList[info] = true
        delayedExecute(delay, function()
            ProjectileList[info] = nil
            projectile.laser(currentPos, targetPos - currentPos, flags)
        end)
    end
    random_enemy = enemy:new{
        pos = Vector2.new(love.graphics.getWidth()/2, 50),
        direction = 1,
        boundaries = {min = Vector2.new(30, 20), max = Vector2.new(love.graphics.getWidth()-60, 170)},
        accumulated_time = 0,
        update = function(self, elapsedTime)
            local resolver = self.resolver
            if not resolver then
                local goal = Vector2.new(math.random(self.boundaries.min.x, self.boundaries.max.x), math.random(self.boundaries.min.y, self.boundaries.max.y))
                resolver = path.Linear(math.random(40, 80), self.pos, goal)
                self.resolver = resolver
            end
            local p, b = resolver(elapsedTime)
            self.pos = p
            if not b then self.resolver = nil end
            -- self.pos = Vector2.new(self.pos.x + self.direction * 100 * elapsedTime, self.pos.y)
            -- if self.pos.x < 0 or self.pos.x + self.size.x > X_MAX then
            --     self.direction = self.direction * -1
            -- end
            self.accumulated_time = self.accumulated_time + elapsedTime
            if self.accumulated_time > 2.5 then
                self.mode = (self.mode + 1) % 12
                local target = player.center()
                aimedFireLaser(self:center(), target, 0.5, {lifetime = 1})
                self.accumulated_time = 0
            end

            if self.health <= 0 then
                GameWon:Fire()
            end
        end,
        step = function(self)
            if not enemy.__enemy_list[self] then return end
            if self.mode == 1 and math.random(5) > 3 then
                local p = self:center()
                projectile.gravityBoundCircle(p.x, p.y)
            elseif self.mode == 3 and math.random(5) > 3 then
                local p = self:center()
                projectile.weakHomingCircle(p, Vector2.new(0, 50))
            elseif self.mode == 5 and math.random(50) == 50 then
                local target = player.center()
                aimedFireLaser(self:center(), target, 1, {reflections = 4})
            elseif self.mode == 7 and math.random(5) > 3 then
                for b = 1, 3 do
                    delayedExecute(b, function()
                        if not enemy.__enemy_list[self] then return end
                        for i = 0, 360, 40 do
                            projectile.spiralCircle(self:center(), 1.5, 100, math.rad(i), 10)
                        end
                    end)
                end
                self.mode = self.mode + 1
                --projectile.spiralCircle(p, 1, 50, 10)
            elseif self.mode == 10 then
                for b = 0, 3 do
                    delayedExecute(b, function()
                        if not enemy.__enemy_list[self] then return end
                        for i = 0, 360, 60 do
                            projectile.delayedChase(self:center(), player, 3, Vector2.fromAngle(i, 150, true), 500, 11.5)
                        end
                    end)
                end
                self.mode = self.mode + 1
            end
        end,
        health = 1000,
        max_health = 1000,
        mode = 6
    }

    keyboard = love.keyboard
    love.graphics.setBackgroundColor(1,1,1)

    love.audio.setVolume(0.25)

    if initial_load then
        music = love.audio.newSource("assets/fck It..mp3", "static")
        music:setLooping(true)
        music:play()
    end
    initial_load = false
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "x" then
        togglePause()
    elseif key == "r" and keyboard.isDown("lctrl") then
--         love.event.quit("restart")
        love.load()
    end
end

function love.focus(f)
    if f and PAUSED then
        togglePause()
    elseif not f and not PAUSED then
        togglePause()
    end
end


-- loop
local speed = 200
main_thread.Stepped:Connect(function(elapsedTime)
    if not ACTIVE then return end
    main_thread.update(elapsedTime)
    if PAUSED then return end
    for physics_object, _ in pairs(physics_objects) do
        physics_object:update(elapsedTime)
    end
    for bullet, _ in pairs(player.bullets) do
        bullet:update(elapsedTime, random_enemy)
    end
    for e, _ in pairs(enemy_list) do
        e:update(elapsedTime)
    end
    for p, _ in pairs(ProjectileList) do
        p:update(elapsedTime)
        if p:hits(player.getHitbox()) then
            print("Projectile:", p)
            ACTIVE = false
            GameEnded:Fire("GAME OVER")
        end
    end

    -- player behavior
    local speed = speed
    if love.keyboard.isDown("lshift") then
        speed = speed / 2
        player.hitbox_radius = 5
    else
        player.hitbox_radius = 7.5
    end
    local up = keyboard.isDown("w")
    local down = keyboard.isDown("s")
    local left = keyboard.isDown("a")
    local right = keyboard.isDown("d")
    local x, y = 0, 0
    if up then y = y + 1 end
    if down then y = y - 1 end
    if left then x = x - 1 end
    if right then x = x + 1 end
    player:move(x * elapsedTime * speed, - y * elapsedTime * speed)
    if not player.can_fire then
        player.fire_cd = math.max(0, player.fire_cd - elapsedTime)
    end
    if player.fire_cd == 0 and not player.can_fire then
        player.fire_cd = player.fire_cd_max
        player.can_fire = true
    end
    if player.can_fire and (love.keyboard.isDown("space") or love.mouse.isDown(1)) then
        player.can_fire = false
        player.fire_bullet(player.center().x, player.center().y - player.size.y / 2)
    end

    ray_start = Vector2.new(1000,1000)
    ray_dir = Vector2.new(love.mouse.getX(), love.mouse.getY())

    love.window.setTitle(tostring(1 / elapsedTime))
end)

function love.update(elapsedTime)
    if not ACTIVE then return end
    --for name, scheduler in pairs(taskscheduler.schedulers) do
    --    scheduler.update(elapsedTime)
    --end

    main_thread.update(elapsedTime)
end

-- draw itself is actually a loop which acts upon any calls to draw i.e. love.graphics.circle
function love.draw()
    player.draw()
    for physics_objects, _ in pairs(physics_objects) do
        physics_objects:draw()
    end
    for bullet, _ in pairs(player.bullets) do
        bullet:draw()
    end
    for e, _ in pairs(enemy_list) do
        e:draw()
    end
    for p, _ in pairs(ProjectileList) do
        p:draw()
    end
    --Interface.ROOT:Draw()

    local r,g,b,a = love.graphics.getColor()
    -- if geometry.CheckRayVsCircle(ray_start, ray_dir, Shapes.Circle.new(player.center().x, player.center().y, player.hitbox_radius)) then
    --     love.graphics.setColor(1, 0, 0)
    -- else
    --     love.graphics.setColor(0, 1, 0)
    -- end
    -- love.graphics.line(ray_start.x, ray_start.y, ray_dir.x, ray_dir.y)
    
    local percent = random_enemy.health / random_enemy.max_health
    love.graphics.setColor(1,0,0)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth() * percent, 20)
    
    if PAUSED then
        love.graphics.setColor(0,0,0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(PAUSED_TEXT, X_MAX / 2, Y_MAX / 2, 0, 2, 2, PAUSED_TEXT:getWidth()/2, PAUSED_TEXT:getHeight()/2)
    end

    love.graphics.setColor(r,g,b,a)


    if not ACTIVE then
        local r,g,b,a = love.graphics.getColor()
        love.graphics.setColor(0,0,0)
        love.graphics.draw(GAME_OVER, X_MAX / 2, Y_MAX / 2, 0, 2, 2, GAME_OVER:getWidth()/2, GAME_OVER:getHeight()/2)
        love.graphics.setColor(r,g,b,a)
    end

end

local main_state = statemanager.CreateState("Main", love.update, love.draw, main_thread)
statemanager.SetState("Main")

-- delayedExecute(10, function()
--     local test = require "test"
--     statemanager.SetState("test")
-- end)
