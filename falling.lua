engine.name = 'Ack'
local ack = require 'ack/lib/ack'
local g = grid.connect()
local BeatClock = require 'beatclock'
local clk = BeatClock.new()

local state = {
  notes = {},
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

function grid_redraw()
  g:all(0)
  for index, note in pairs(state.notes) do
    g:led(note.x, note.y, 10)
  end
  g:refresh()
end

function g.key(x, y, z)
  if z == 0 then
    addNote(x, y)
  end
end

function addNote(x, y)
  table.insert(state.notes, {x = x, y = y})
end

function tick()
  for index, note in pairs(state.notes) do
    print('---------------')
    tab.print(note)
    if note.x == 16 then
      engine.trig(note.y - 1)
      -- table.remove(state.notes, index)
      state.notes[index] = nil
    else
      note.x = note.x + 1
    end
  end
  grid_redraw()
end

