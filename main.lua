class = require "lib.30log"
tiny = require "lib.tiny"
gamestate = require "lib.gamestate" -- slightly modified to play nice;y with 30log
local Intro = require "src.states.Intro"
local Level = require "src.states.Level"

local assets = nil

local beholder = require "lib.beholder"

local paused = false
local pauseNextFrame = false
local pauseCanvas = nil
local drawFilter = tiny.requireAll('isDrawSystem')
local updateFilter = tiny.rejectAny('isDrawSystem')

function love.keypressed(k)
    beholder.trigger("keypress", k)
end

function love.keyreleased(k)
    beholder.trigger("keyrelease", k)
end

function love.load()
	love.mouse.setVisible(false)
	assets = require "src.assets" -- load assets
	gamestate.registerEvents()
	gamestate.switch(Intro())
	assets.snd_music:play()
	assets.snd_music:setLooping(true)
	love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.draw()
	if paused then
		love.graphics.setColor(0.35, 0.35, 0.35, 1)
		love.graphics.draw(pauseCanvas, 0, 0)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(assets.fnt_hud)
		love.graphics.printf("Paused - P to Resume", love.graphics.getWidth() * 0.5 - 125, love.graphics.getHeight() * 0.4, 250, "center")
	else
		local dt = love.timer.getDelta()
		if world then
			world:update(dt, drawFilter)
		end
	end
end

function love.update(dt)
    if world then
        world:update(dt, updateFilter)
    end
    local s = gamestate.current()
    if s and s.restartOnSpace and love.keyboard.isDown("space") then
        local TransitionScreen = require "src.entities.TransitionScreen"
        world:add(TransitionScreen(true, Intro()))
    end
end

function love.resize(w, h)
	pauseCanvas = love.graphics.newCanvas(w, h)
	if camera then
		camera:setWindow(0, 0, w, h)
	end
	if paused then
		love.graphics.setCanvas(pauseCanvas)
		world:update(0)
		love.graphics.setCanvas()
	end
	beholder.trigger('resize', w, h)
end

-- quitting
beholder.observe("keypress", "escape", love.event.quit)

-- pausing
beholder.observe("keypress", "p", function()
	paused = not paused
	if paused then
		love.graphics.setCanvas(pauseCanvas)
		world:update(0)
		love.graphics.setCanvas()
	end
end)

-- toggle music
beholder.observe("keypress", "m", function()
	local vol = assets.snd_music:getVolume()
	if vol == 0 then
		assets.snd_music:setVolume(1)
	else
		assets.snd_music:setVolume(0)
	end
end)

-- toggle fullscreen
beholder.observe("keypress", "\\", function()
	local fs = love.window.getFullscreen()
	if fs then
		love.window.setMode(900, 600, {resizable = true})
	else
		local w, h = love.window.getDesktopDimensions()
		love.window.setMode(w, h, {fullscreen = true})
	end
	love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end)
