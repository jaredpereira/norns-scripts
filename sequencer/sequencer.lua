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
  meta = {
    sequence = {1},
    position = 1,
    mode = false
  },
  clock = true,
  position = 1,
  copying = 0
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
  local playingSequence = state.meta.sequence[state.meta.position]
  local step = state.sequences[playingSequence][state.position]
  for sample, triggered in pairs(step) do
    if triggered then
      engine.trig(sample-1)
    end
  end
  if state.position == 16 then
    state.meta.position = (state.meta.position % #state.meta.sequence) + 1
  end
  state.position = (state.position % 16) + 1
  grid_redraw()
end

------ EVENTS ------

function g.event(x,y,z)
  if state.meta.mode then
    if z == 1 then
      setMetaStep(x, y)
    end
    return
  end

  if y <= 4 and z == 0 then
    toggleStep(x, y)
  end

  if y == 5 and z==1 then
    setPosition(x)
  end

  if y == 6 and x <=8 then
    if z == 1 and state.copying == 0 then
      state.copying = x
      changeActiveSequence(x)
    end
    if z == 0 then
      if state.copying == x then
        state.copying = 0
      else
        copySequence(x)
      end
    end
  end
end

function key(n, z)
  if n == 1 and z == 1 then
   toggleMetaMode()
  end

  if state.meta.mode and z == 0 then
    if n ==2 then
      decreaseMetaSequenceLength()
    elseif n == 3 then
      increaseMetaSequenceLength()
    end
    return
  end

  if n == 2 and z == 0 then
    toggleClock()
  elseif n == 3 and z == 0 then
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
  grid_redraw()
end

function changeActiveSequence(x)
  if #state.meta.sequence == 1 then
    state.meta.sequence[1] = x
  end
  state.activeSequence = x
  grid_redraw()
end

function toggleCopying()
  state.copying = state.copying == false
end

function toggleMetaMode()
  state.meta.mode = state.meta.mode == false
end

function setMetaStep(x, y)
  if x <= #state.meta.sequence then
    state.meta.sequence[x] = y
  end
end

function increaseMetaSequenceLength()
  local length = #state.meta.sequence
  if length < 8 then
    state.meta.sequence[length + 1] = 1
  end
end

function decreaseMetaSequenceLength()
  local length = #state.meta.sequence
  if length > 1 then
    state.meta.sequence[length] = nil
  end
end

function copySequence(x)
  if state.copying == 0 then return end
  for step, value in pairs(state.sequences[state.copying]) do
    for sample, triggered in pairs(value) do
      state.sequences[x][step][sample] = triggered
    end
  end
end

------- UI -------

function grid_redraw()
  g.all(0)

  if state.meta.mode then
    for i=1,8 do
      g.led(state.meta.position, i, 5)
    end
    for step, value in pairs(state.meta.sequence) do
      g.led(step, value, 10)
    end
    g.refresh()
    return
  end

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

  g.led(state.meta.sequence[state.meta.position], 6, 5)
  g.led(state.activeSequence, 6, 10)
  g.refresh()
end

function redraw()
  screen.clear()
  screen.text('jss')
  screen.update()
end
