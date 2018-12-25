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

function init()
  -- State
  state = {
    steps = {},
    clock = true,
    position = 1,
  }
  for i=1,16 do
    table.insert(state.steps, {false,false,false,false})
  end

  -- Ack setup
  for channel=1,4 do
    ack.add_channel_params(channel)
  end
  ack.add_effects_params()
  
  params:read("tehn/playfair.pset")
  params:bang()
  

  -- BeatClock
  clk.on_step = countStep
  clk.on_select_internal = function() clk:start() end
  
  clk:add_clock_params()
  clk:start()
end

function countStep()
  for instrument, triggered in pairs(state.steps[state.position]) do
    if triggered then
      engine.trig(instrument-1)
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
  state.steps[x][y] = state.steps[x][y] == false
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
    state.steps[i] = {false,false,false,false}
  end
end

------- UI -------

function grid_redraw()
  g.all(0)
  for step, value in pairs(state.steps) do
    for instrument, trigged in pairs(value) do
      if step == state.position then
        g.led(step, instrument, 5)
      end
      if trigged then
        g.led(step,instrument, 10)
      end
    end
  end
  g.refresh()
end

function redraw()
  screen.clear()
  screen.text('jss')
  screen.update()
end
