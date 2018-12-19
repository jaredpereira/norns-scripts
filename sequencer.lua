-- jss (jared's simple sequencer)
--
-- requires a grid
-- press any key in rows 1-4

engine.name = 'Ack'

local g = grid.connect()

local ack = require 'jah/ack'
local BeatClock = require 'beatclock'

function init()
  -- State
  steps = {}
  position = 1
  for i=1,16 do
    table.insert(steps, {false,false,false,false})
  end

  -- Ack setup
  for channel=1,4 do
    ack.add_channel_params(channel)
  end
  ack.add_effects_params()

  params:read("tehn/playfair.pset")
  params:bang()

  -- clock setup

  counter = metro.alloc()
  counter.time = 0.05
  counter.count = 0
  counter.callback = countStep

  counter:start()
end

function countStep()
  position = (position % 16) + 1
  for instrument, triggered in pairs(steps[position]) do
    if triggered then
      print('triggered?')
      engine.trig(instrument-1)
    end
  end
  grid_redraw()
end
--------------------------- 

function g.event(x,y,z)
  if z == 0 then
    if y <= 4 then
      toggleStep(x, y)
    end
  end
end

function toggleStep(x,y)
  steps[x][y] = steps[x][y] == false
  grid_redraw()
end

function grid_redraw()
  g.all(0)
  for step, value in pairs(steps) do
    for instrument, trigged in pairs(value) do
      if step == position then
        g.led(step, instrument, 5)
      end
      if trigged then
        g.led(step,instrument, 10)
      end
    end
  end
  g.refresh()
end
