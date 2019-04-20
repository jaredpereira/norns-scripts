engine.name = 'Ack'
local ack = require 'ack/lib/ack'
local g = grid.connect()
local BeatClock = require 'beatclock'
local clk = BeatClock.new()

local state = {
  notes = {},
  emitters = {},
  selectedEmitter = nil,
  playing = true
}

function init()
  -- BeatClock
  clk.on_step = tick 
  clk.on_select_internal = function() clk:start() end

  clk:add_clock_params()
  clk:start()

  -- Ack setup
  ack.add_params()
  params:read()
  params:bang()
end

function tick()
  for index, emitter in pairs(state.emitters) do
    if emitter.clock >= emitter.speed then
      addNote(emitter.x, emitter.y)
      emitter.clock = 0
    else
      emitter.clock = emitter.clock + 1
    end
  end

  for index, note in pairs(state.notes) do
    if note.x == 16 then
      engine.trig(note.y - 1)
      state.notes[index] = nil
    else
      note.x = note.x + 1
    end
  end
  grid_redraw()
end

----------------
-- INPUTS
----------------

function enc(num, direction)
  if num == 2 then
    changeSpeed(direction)
  end
  redraw()
end

function key(num, state)
  if num == 2 and state == 0 then
    togglePlaying()
  end

  if num == 3 and state == 0 then
    removeEmitter()
  end
end

function g.key(x, y, z)
  if z == 0 then
    removeSelectedEmitter()
  end

  if  z == 1 then
    addEmitter(x, y)
    setSelectedEmitter(x, y)
  end
end

-------------------
-- DRAWING
-------------------

function redraw()
  screen.clear()

  if state.selectedEmitter then
    screen.move(10,10)
    screen.text('speed' .. state.selectedEmitter.speed)
  end
  screen.update()
end

function grid_redraw()
  g:all(0)
  for index, note in pairs(state.notes) do
    g:led(note.x, note.y, 5)
  end
  for index, emitter in pairs(state.emitters) do
    g:led(emitter.x, emitter.y, 10)
  end
  g:refresh()
end

----------------
-- ACTIONS
----------------

function removeSelectedEmitter()
  state.selectedEmitter = nil
  redraw()
end

function setSelectedEmitter(x, y)
  for _, emitter in pairs(state.emitters) do
    if x == emitter.x and emitter.y == y then
      state.selectedEmitter = emitter
    end
  end
  redraw()
end

function changeSpeed(x)
  local emitter = state.selectedEmitter
  if emitter then
    emitter.speed = emitter.speed + x
    if emitter.speed <= 0 then
      emitter.speed = 0
    end
  end
  grid_redraw()
  redraw()
end

function removeEmitter()
  local emitter = state.selectedEmitter
  for key, value in pairs(state.emitters) do
    if emitter.x == value.x and emitter.y == value.y then
      state.emitters[key] = nil
      state.selectedEmitters = nil
    end
  end
end

function addEmitter(x, y)
  for _, emitter in pairs(state.emitters)do
    if emitter.x == x and emitter.y == y then
      return
    end
  end
  table.insert(state.emitters, {x = x, y=y, speed = 4, clock = 4})
end

function togglePlaying()
  if state.playing then
    clk:stop()
  else
    clk:start()
  end
  state.playing = state.playing == false
end

function addNote(x, y)
  table.insert(state.notes, {x = x, y = y})
end
