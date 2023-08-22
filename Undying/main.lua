-- Love2D Zombie Chasing Player with Shooting, Reloading, Game Over, and Restart

res = require 'resolution_solution'         -- provides automatic window resizing routines
-- https://github.com/Vovkiv/resolution_solution

local gamestate = "playing"  -- "playing" or "gameover"
local bullets = {}  -- Table to store bullets
local maxBullets = 6  -- Maximum number of bullets
local bulletsRemaining = maxBullets  -- Bullets available for shooting
local zombies = {}  -- Table to store zombies
local maxZombieKillDistance = 100  -- Maximum distance to kill a zombie
local MAX_ZOMBIES = 3              -- starts at this value and grows with each wave

function love.resize(w, h)
	res.resize(w, h)
end

function love.load()

    -- do window resizing things
    res.init({width = 1920, height = 1080, mode = 2})
	local width, height = love.window.getDesktopDimensions( 1 )
	res.setMode(width, height, {resizable = true})

    IMAGE = {}      -- a table that holds all images
    IMAGE[1] = love.graphics.newImage("bground_dirt.jpg")

    player = {
        x = 100,
        y = 100,
        speed = 200
    }

    font = love.graphics.newFont(24)
end

function love.update(dt)
    print(MAX_ZOMBIES)
    if gamestate == "playing" then
        -- Player movement using arrow keys
        if love.keyboard.isDown("up") then
            player.y = player.y - player.speed * dt
        end
        if love.keyboard.isDown("down") then
            player.y = player.y + player.speed * dt
        end
        if love.keyboard.isDown("left") then
            player.x = player.x - player.speed * dt
        end
        if love.keyboard.isDown("right") then
            player.x = player.x + player.speed * dt
        end

        -- Zombie chasing player and zombie spawning
        for _, zombie in ipairs(zombies) do
            local dx = player.x - zombie.x
            local dy = player.y - zombie.y
            local distance = math.sqrt(dx^2 + dy^2)
            local zombieSpeedX = zombie.speed * (dx / distance)
            local zombieSpeedY = zombie.speed * (dy / distance)

            zombie.x = zombie.x + zombieSpeedX * dt
            zombie.y = zombie.y + zombieSpeedY * dt

            if checkCollision(player.x, player.y, 50, 50, zombie.x, zombie.y, 50, 50) then
                gamestate = "gameover"
            end
        end

        -- Update bullet positions and check for collisions
        for i = #bullets, 1, -1 do
            local bullet = bullets[i]
            bullet.x = bullet.x + bullet.speed * dt

            if bullet.x > love.graphics.getWidth() then
                table.remove(bullets, i)
            else
                -- Check for bullet collision with zombies
                for j = #zombies, 1, -1 do
                    local zombie = zombies[j]
                    if checkCollision(bullet.x, bullet.y, 10, 5, zombie.x, zombie.y, 50, 50) then
                        table.remove(bullets, i)
                        if zombie.health > 1 then
                            zombie.health = zombie.health - 1
                        else
                            table.remove(zombies, j)
                            bulletsRemaining = bulletsRemaining + 1
                        end
                    end
                end
            end
        end

        -- Spawn new zombies when all zombies are killed
        if #zombies == 0 then
            for _ = 1, MAX_ZOMBIES do
                local newZombie = { x = math.random(0, love.graphics.getWidth()), y = math.random(0, love.graphics.getHeight()), speed = 100, health = 3 }
                table.insert(zombies, newZombie)
            end
            MAX_ZOMBIES = MAX_ZOMBIES + 1
        end

        -- Check distance to kill a zombie
        if love.keyboard.isDown("d") then
            for i = #zombies, 1, -1 do
                local zombie = zombies[i]
                local dx = player.x - zombie.x
                local dy = player.y - zombie.y
                local distance = math.sqrt(dx^2 + dy^2)
                if distance <= maxZombieKillDistance then
                    table.remove(zombies, i)
                end
            end
        end
    end
end

function love.draw()
    love.graphics.setFont(font)

    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(IMAGE[1], 0,0)

    if gamestate == "playing" then
        -- Draw the player character
        love.graphics.setColor(1, 0, 0) -- Set color to red
        love.graphics.rectangle("fill", player.x, player.y, 50, 50)

        -- Draw bullets
        love.graphics.setColor(0, 0, 1) -- Set color to blue for bullets
        for _, bullet in ipairs(bullets) do
            love.graphics.rectangle("fill", bullet.x, bullet.y, 10, 5)
        end

        -- Draw bullet count and reload info
        love.graphics.setColor(1, 1, 1) -- Set color to white
        love.graphics.print("Bullets: " .. bulletsRemaining .. "/" .. maxBullets, 20, 20)
        love.graphics.print("Press F to shoot", 20, 50)
        love.graphics.print("Press R to reload", 20, 80)
        love.graphics.print("Press D to kill a zombie", 20, 110)
    elseif gamestate == "gameover" then
        -- Draw "Game Over" message
        love.graphics.setColor(1, 1, 1) -- Set color to white
        love.graphics.print("Game Over", 280, 200)

        -- Draw "Try again" button
        love.graphics.rectangle("fill", 320, 250, 120, 40)
        love.graphics.setColor(0, 0, 0) -- Set color to black
        love.graphics.print("Try again", 330, 260)
    end

    -- Draw zombies
    love.graphics.setColor(0, 1, 0) -- Set color to green for zombies
    for _, zombie in ipairs(zombies) do
        love.graphics.rectangle("fill", zombie.x, zombie.y, 50, 50)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if gamestate == "playing" then
        if key == "f" and bulletsRemaining > 0 then
            local bullet = { x = player.x + 50, y = player.y + 25, speed = 400 }
            table.insert(bullets, bullet)
            bulletsRemaining = bulletsRemaining - 1
        elseif key == "r" then
            bulletsRemaining = maxBullets
        end
    elseif gamestate == "gameover" then
        if key == "return" then
            gamestate = "playing"
            player.x = 100
            player.y = 100
            bullets = {}
            bulletsRemaining = maxBullets
            zombies = {}  -- Reset zombies
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    if gamestate == "gameover" then
        if x >= 320 and x <= 440 and y >= 250 and y <= 290 then
            gamestate = "playing"
            player.x = 100
            player.y = 100
            bullets = {}
            bulletsRemaining = maxBullets
            zombies = {}  -- Reset zombies
        end
    end
end

-- Function to check collision between two rectangles
function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end
