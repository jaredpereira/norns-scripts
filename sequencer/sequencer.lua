-- jss (jared's simple sequencer)
-- v 0.0.2
--
-- requires a grid
-- press any key in rows 1-4
--
-- row 5 jumps to step

engine.name = 'Ack'
local ack = require 'jah/ack'

local g = grid.connect()

local BeatClock = require 'beatclock'

local clk = BeatClock.new()

local state = {
  sequences = {},
  activeSequence = 1,
  clock = true,
  position = 1,
}

function init()
  -- BeatClock
  clk.on_step = countStep
  clk.on_select_internal = function() clk:start() end
  
  clk:add_clock_params()
  clk:start()

  -- Ack setup
  for channel=1,4 do
    ack.add_channel_params(channel)
  end
  ack.add_effects_params()
  
  params:read("tehn/playfair.pset")
  params:bang()
  

  -- State
  for i=1,8 do
    local sequence = {}
    for i=1,16 do
      table.insert(sequence, {false,false,false,false})
    end
    table.insert(state.sequences, sequence)
  end
end

function countStep()
  local step = state.sequences[state.activeSequence][state.position]
  for sample, triggered in pairs(step) do
    if triggered then
      engine.trig(sample-1)
    end
  end
  state.position = (state.position % 16) + 1
  grid_redraw()
end

------ EVENTS ------

function g.event(x,y,z)
  if y <= 4 and z == 0 then
    toggleStep(x, y)
  end

  if y == 5 and z==1 then
    setPosition(x)
  end

  if y == 6 and x <= 8 and z  == 0 then
    changeActiveSequence(x)
  end
end

function key(n, z)
  if n == 2 and z == 1 then
    toggleClock()
  end

  if n == 3 and z == 1 then
    clearPattern()
  end
end

------ ACTIONS ------

function toggleStep(x,y)
  local step = state.sequences[state.activeSequence][x][y]
  state.sequences[state.activeSequence][x][y] = step == false
  grid_redraw()
end

function setPosition(x)
  state.position = x
  grid_redraw()
end

function toggleClock()
  if state.clock then
    clk:stop()
  else
    clk:start()
  end
  state.clock = state.clock == false
end

function clearPattern()
  for i=1,16 do
    state.sequences[state.activeSequence][i] = {false,false,false,false}
  end
end

function changeActiveSequence(x)
  state.activeSequence = x
  grid_redraw()
end

------- UI -------

function grid_redraw()
  g.all(0)
  for step, value in pairs(state.sequences[state.activeSequence]) do
    for y, triggered in pairs(value) do
      if step == state.position then
        g.led(step, y, 5)
      end
      if triggered then
        g.led(step, y, 10)
      end
    end
  end
  for i=1,8 do
    g.led(i,6,3)
  end
  g.led(state.activeSequence, 6, 10)
  g.refresh()
end

function redraw()
  screen.clear()
  screen.text('jss')
  screen.update()
end
