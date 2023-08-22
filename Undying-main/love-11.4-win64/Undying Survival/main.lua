local gamestate = "menu"
local bullets = {}
local maxBullets = 5
local bulletsRemaining = maxBullets
local zombies = {}
local maxZombieKillDistance = 100
local wave = 0

local pauseMenu = false
local menuBG
local background
local font

local player
local playerHealth = 100

local portalImage
local portalX
local hasPirateSword
local showMessage = false
local messageTimer = 0
local messageDuration = 4

local isHoldingD = false
local currentBackground
local backgroundImages = {
    normal = love.graphics.newImage("background.png"),
    changed = love.graphics.newImage("background-2.png")
}

function love.load()
    menuBG = love.graphics.newImage("menuBG.png")
    background = love.graphics.newImage("background.png")
    portalImage = love.graphics.newImage("portal.png")
    currentBackground = backgroundImages.normal

    player = {
        x = 100,
        y = 100,
        speed = 200
    }

    font = love.graphics.newFont(24)

    portalX = love.graphics.getWidth() - portalImage:getWidth() - 20
end

function love.keypressed(key)
    if gamestate == "playing" then
        if key == "f" and bulletsRemaining > 0 then
            local bullet = { x = player.x + 50, y = player.y + 25, speed = 400 }
            table.insert(bullets, bullet)
            bulletsRemaining = bulletsRemaining - 1
            love.updateZombieSpawn()
        elseif key == "r" then
            bulletsRemaining = maxBullets
        elseif key == "d" then
            isHoldingD = true
        elseif key == "escape" then
            gamestate = "paused"
            pauseMenu = true
        end
    elseif gamestate == "gameover" then
        if key == "return" then
            resetGame()
        end
    elseif gamestate == "paused" then
        if key == "escape" then
            gamestate = "playing"
            pauseMenu = false
        end
    end
end

function love.keyreleased(key)
    if gamestate == "playing" then
        if key == "d" then
            isHoldingD = false
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if gamestate == "menu" then
        if button == 1 and y >= love.graphics.getHeight() / 2 + 50 and y <= love.graphics.getHeight() / 2 + 90 then
            gamestate = "playing"
        end
    elseif gamestate == "playing" and wave >= 10 then
        local mouseX, mouseY = love.mouse.getPosition()

        if mouseX >= portalX and mouseX <= portalX + portalImage:getWidth() and
           mouseY >= love.graphics.getHeight() - portalImage:getHeight() - 20 and mouseY <= love.graphics.getHeight() - 20 then
            currentBackground = backgroundImages.changed
            wave = 0
            zombies = {}
            love.updateZombieSpawn()
            showMessage = true
            messageTimer = messageDuration
        end
    elseif gamestate == "gameover" then
        if button == 1 and y >= love.graphics.getHeight() / 2 + 50 and y <= love.graphics.getHeight() / 2 + 90 then
            resetGame()
        end
    elseif gamestate == "paused" then
        if button == 1 then
            if y >= love.graphics.getHeight() / 2 + 50 and y <= love.graphics.getHeight() / 2 + 90 then
                gamestate = "playing"
                pauseMenu = false
            elseif y >= love.graphics.getHeight() / 2 + 100 and y <= love.graphics.getHeight() / 2 + 140 then
                gamestate = "menu"
                pauseMenu = false
            end
        end
    end
end

function love.update(dt)
    if gamestate == "playing" then
        if not pauseMenu then
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

            for _, zombie in ipairs(zombies) do
                local dx = player.x - zombie.x
                local dy = player.y - zombie.y
                local distance = math.sqrt(dx^2 + dy^2)
                local zombieSpeedX = zombie.speed * (dx / distance)
                local zombieSpeedY = zombie.speed * (dy / distance)

                zombie.x = zombie.x + zombieSpeedX * dt
                zombie.y = zombie.y + zombieSpeedY * dt

                if checkCollision(player.x, player.y, 50, 50, zombie.x, zombie.y, 50, 50) then
                    playerHealth = playerHealth - 1
                    if playerHealth <= 0 then
                        gamestate = "gameover"
                    end
                end
            end

            for i = #bullets, 1, -1 do
                local bullet = bullets[i]
                bullet.x = bullet.x + bullet.speed * dt

                if bullet.x > love.graphics.getWidth() then
                    table.remove(bullets, i)
                else
                    for j = #zombies, 1, -1 do
                        local zombie = zombies[j]
                        if checkCollision(bullet.x, bullet.y, 10, 5, zombie.x, zombie.y, 50, 50) then
                            table.remove(bullets, i)
                            if zombie.health > 1 then
                                zombie.health = zombie.health - 1
                            else
                                table.remove(zombies, j)
                                bulletsRemaining = bulletsRemaining + 1
                                love.updateZombieSpawn()
                            end
                        end
                    end
                end
            end

            if isHoldingD then
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

        if showMessage then
            messageTimer = messageTimer - dt
            if messageTimer <= 0 then
                showMessage = false
            end
        end

        love.updateZombieSpawn()
    end
end

function love.updateZombieSpawn()
    if #zombies == 0 then
        wave = wave + 1
        for _ = 1, wave * 3 do
            local newZombie = { x = math.random(0, love.graphics.getWidth()), y = math.random(0, love.graphics.getHeight()), speed = 100, health = 3 }
            table.insert(zombies, newZombie)
        end
    end
end

function love.draw()
    if gamestate == "menu" then
        love.graphics.draw(menuBG, 0, 0)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(font)
        love.graphics.print("Undying Survival", love.graphics.getWidth() / 2 - font:getWidth("Undying Survival") / 2, love.graphics.getHeight() / 2 - 100)
        love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 80, love.graphics.getHeight() / 2 + 50, 160, 40)
        love.graphics.print("Play", love.graphics.getWidth() / 2 - font:getWidth("Play") / 2, love.graphics.getHeight() / 2 + 60)
    elseif gamestate == "playing" then
        love.graphics.draw(currentBackground, 0, 0)

        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", player.x, player.y, 50, 50)

        love.graphics.setColor(0, 0, 1)
        for _, bullet in ipairs(bullets) do
            love.graphics.rectangle("fill", bullet.x, bullet.y, 10, 5)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Bullets: " .. bulletsRemaining .. "/" .. maxBullets, 20, 20)
        love.graphics.print("Health: " .. playerHealth, 20, 50)
        love.graphics.print("Press R to reload", 20, 80)
        love.graphics.print("Press D to kill a zombie", 20, 110)
        love.graphics.print("Wave: " .. wave, 20, 140)

        for _, zombie in ipairs(zombies) do
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", zombie.x, zombie.y, 50, 50)
        end

        if wave >= 10 then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(portalImage, portalX, love.graphics.getHeight() - portalImage:getHeight() - 20)
        end

        if showMessage then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("You got the pirate sword now go to that portal", 20, love.graphics.getHeight() - 40)
        end

    elseif gamestate == "gameover" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Game Over", love.graphics.getWidth() / 2 - font:getWidth("Game Over") / 2, love.graphics.getHeight() / 2 - 60)

        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 80, love.graphics.getHeight() / 2 + 50, 160, 40)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Retry", love.graphics.getWidth() / 2 - font:getWidth("Retry") / 2, love.graphics.getHeight() / 2 + 60)
    elseif gamestate == "paused" then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Paused", 0, love.graphics.getHeight() / 2 - 60, love.graphics.getWidth(), "center")

        love.graphics.setFont(font)
        love.graphics.printf("Undying Survival 1.1", 0, love.graphics.getHeight() / 2 - 120, love.graphics.getWidth(), "center")
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 80, love.graphics.getHeight() / 2 + 50, 160, 40)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 80, love.graphics.getHeight() / 2 + 100, 160, 40)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Return Game", love.graphics.getWidth() / 2 - font:getWidth("Return Game") / 2, love.graphics.getHeight() / 2 + 60)
        love.graphics.print("Exit Game", love.graphics.getWidth() / 2 - font:getWidth("Exit Game") / 2, love.graphics.getHeight() / 2 + 110)
    end
end

function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function resetGame()
    gamestate = "playing"
    player.x = 100
    player.y = 100
    bullets = {}
    bulletsRemaining = maxBullets
    zombies = {}
    wave = 0
    playerHealth = 5
end

love.updateZombieSpawn()
