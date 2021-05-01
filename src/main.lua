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
table.unpack = unpack

local GameEnded = BindableEvent.new()

local delayedExecute = taskscheduler.delay

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

math.randomseed(os.time())
-- initialization
function love.load()
    ProjectileList = projectile.ProjectileList
    physics_objects = {}
    GRAVITY = -9.81 * 10
    -- grab window size
    Y_MAX = love.graphics.getHeight()
    X_MAX = love.graphics.getWidth()
    
    PAUSED = false
    ACTIVE = true
    local regular_font = love.graphics.getFont()
    GAME_OVER = love.graphics.newText(regular_font, "GAME OVER!")
    PAUSED_TEXT = love.graphics.newText(regular_font, "PAUSED")

    function clear_list(list)
        for key, _ in pairs(list) do
            list[key] = nil
        end
    end

    enemy_list = enemy.__enemy_list
    random_enemy = enemy:new{
        pos = Vector2.new(love.graphics.getWidth()/2, 50),
        direction = 1,
        update = function(self, elapsedTime)
            --x = self.pos_x
            self.pos = Vector2.new(self.pos.x + self.direction * 100 * elapsedTime, self.pos.y)
            if self.pos.x < 0 or self.pos.x + self.size.x > X_MAX then
                self.direction = self.direction * -1
            end
            --print(self.mode)
            -- if math.random(150) == 150 then
            --     print("fired a laser")
            --     --projectile.laser(Vector2.new(self.pos_x, self.pos_y), Vector2.new(1, 0):Rotate(math.random(0, 360), true), {reflections = 4})
            --     local target = player.center()
            --     -- delayedExecute(1, function()
            --     --     local s = random_enemy:center()
            --     --     projectile.laser(s, target - s, {reflections = 4})
            --     -- end)
            --     aimedFireLaser(target, 1, {reflections = 4})
            -- end
            if self.health <= 0 then
                GameWon:Fire()
            end
        end,
        step = function(self)
            if self.mode == 1 and math.random(5) > 3 then
                local p = self:center()
                projectile.gravityBoundCircle(p.x, p.y)
            elseif self.mode == 3 and math.random(5) > 3 then
                local p = self:center()
                projectile.weakHomingCircle(p, Vector2.new(0, 50))
            elseif self.mode == 5 and math.random(50) == 50 then
                local target = player.center()
                aimedFireLaser(target, 1, {reflections = 4})
            end
        end,
        health = 1000,
        max_health = 1000,
        mode = 1
    }
    function aimedFireLaser(targetPos, delay, reflections)
        local info = {
            draw = function(self)
                local r,g,b,a = love.graphics.getColor()
                love.graphics.setColor(0, 0, 1, delay - self.time)
                local c = random_enemy:center()
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
            local s = random_enemy:center()
            projectile.laser(s, targetPos - s, reflections)
        end)
    end
    
    local function some_loop() delayedExecute(2.5, function() random_enemy.mode = (random_enemy.mode + 1) % 6; some_loop() end) end
    some_loop()
    local function execution_loop()
        delayedExecute(2.5, function()
            --local s = Vector2.new(random_enemy.pos_x, random_enemy.pos_y)
            local target = player.center()
            --projectile.laser(Vector2.new(random_enemy.pos_x, random_enemy.pos_y), player.center() - s)
            -- delayedExecute(0.5, function()
            --     local s = random_enemy:center()
            --     projectile.laser(s, target - s)
            --     execution_loop()
            -- end)
            aimedFireLaser(target, 0.5)
            execution_loop()
        end)
    end
    execution_loop()

    keyboard = love.keyboard
    love.graphics.setBackgroundColor(1,1,1)

    love.audio.setVolume(0.25)
    love.audio.play(love.audio.newSource("assets/crystalized river.mp3", "static"))
    
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "x" then
        PAUSED = not PAUSED
    elseif key == "r" and keyboard.isDown("lctrl") then
        love.event.quit("restart")
    end
end

function love.focus(f)
    if f then
        PAUSED = false
    elseif not f then
        PAUSED = true
    end
end


-- loop
local speed = 200
function love.update(elapsedTime)
    if not ACTIVE then return end
    if PAUSED then return end
    taskscheduler.update(elapsedTime)

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
            print("intersected hello???")
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