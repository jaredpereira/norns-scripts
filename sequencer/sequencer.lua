-- jss (jared's simple sequencer)
-- v 0.0.3
--
-- requires a grid
-- press any key in rows 1-4
--
-- row 5 jumps to step

engine.name = 'Ack'
local ack = require'ack/lib/ack'
local g = grid.connect()
local BeatClock = require 'beatclock'
local clk = BeatClock.new()

local state = {
  sequences = {},
  activeSequence = 1,
  meta = {
    sequence = {1},
    position = 1,
  },
  motion = {
    selectedTrack = 1,
    selectedNote = nil
  },
  mode = "sequence", --possible modes: sequence, meta, motion
  clock = true,
  position = 1,
  queuedPosition = nil,
  copying = 0
}

function init()
  -- BeatClock
  clk.on_step = countStep
  clk.on_select_internal = function() clk:start() end

  clk:add_clock_params()
  clk:start()

  -- Ack setup
  ack.add_params()
  params:bang()

  -- State
  for i=1,8 do
    local sequence = {}
    for i=1,16 do
      table.insert(sequence, {0,0,0,0,0,0})
    end
    table.insert(state.sequences, sequence)
  end
end

function countStep()
  if state.position == 16 then
    state.meta.position = (state.meta.position % #state.meta.sequence) + 1
  end
  if state.queuedPosition then
    state.position = state.queuedPosition
    state.queuedPosition = nil
  else
    state.position = (state.position % 16) + 1
  end
  grid_redraw()

  local playingSequence = state.meta.sequence[state.meta.position]
  local step = state.sequences[playingSequence][state.position]
  engine.multiTrig(step[1], step[2], step[3], step[4], step[5], step[6], 0 ,0)
end

------ EVENTS ------

function g.key(x, y, z)
  if state.mode == "meta" then
    if z == 1 then
      setMetaStep(x, y)
    end
    return
  end

  if state.mode == 'sequence' then
    if y <= 6 and z == 0 then
      toggleStep(x, y)
    end

    if y == 7 and z==1 then
      setPosition(x)
    end

    if y == 8 and x <=8 then
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

  if state.mode == 'motion' then
    if y <= 6 and z == 1 then
      setSelectedTrack(y)
      setSelectedNote({x,y})
    elseif y<=6 and z ==0 then
      setSelectedNote(nil)
    end
  end

end

function key(n, z)
  if n == 1 and z == 1 then
    clearPattern()
  end

  if n == 2 and z == 1 then
    toggleClock()
  elseif n == 3 and z == 0 then
    toggleMode()
  end
end

function enc(n, direction)
  print(n, direction)
  if n == 3 then
    setBPM(direction)
  end
  if (state.mode == "meta") then
    if n == 2 then
     changeMetaLength(direction) 
    end
  end
  if state.mode == 'motion' then
    if n == 2 then
      setPitch(direction)
    end
  end
end

------ ACTIONS ------

function toggleStep(x,y)
  local step = state.sequences[state.activeSequence][x][y]
  state.sequences[state.activeSequence][x][y] = (step + 1) % 2
  grid_redraw()
end

function setPosition(x)
  state.queuedPosition = x
  grid_redraw()
end

function toggleClock()
  if state.clock then
    clk:stop()
  else
    clk:start()
  end
  state.clock = state.clock == false
  redraw()
end

function clearPattern()
  for i=1,16 do
    state.sequences[state.activeSequence][i] = {0,0,0,0,0,0}
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

function toggleMode()
  if state.mode == "sequence" then
    state.mode = "motion"
  elseif state.mode == "motion" then
    state.mode = "meta"
  elseif state.mode == "meta" then
    state.mode = "sequence"
  end
  redraw()
end

function setMetaStep(x, y)
  if x <= #state.meta.sequence then
    state.meta.sequence[x] = y
  end
  grid_redraw()
end

function changeMetaLength(x)
  local length = #state.meta.sequence
  if x == 1 then
    if length < 8 then
      state.meta.sequence[length + 1] = 1
    end
  elseif length > state.meta.position then
      state.meta.sequence[length] = nil 
  end
  grid_redraw()
end 

function setSelectedTrack(track)
  state.motion.selectedTrack = track
end

function setSelectedNote(note)
  state.motion.selectedNote = note
end

function setPitch(direction)
  local param = tostring(state.motion.selectedTrack) .. '_speed'
  params:set(param, params:get(param) + (direction/10))
end

function copySequence(x)
  if state.copying == 0 then return end
  for step, value in pairs(state.sequences[state.copying]) do
    for sample, triggered in pairs(value) do
      state.sequences[x][step][sample] = triggered
    end
  end
end

function setBPM(x)
  local bpm = params:get('bpm')
  params:set('bpm', bpm + x)
  redraw()
end


------- UI -------

function grid_redraw()
  g:all(0)

  if state.mode == 'meta' then
    for i=1,8 do
      g:led(state.meta.position, i, 5)
    end
    for step, value in pairs(state.meta.sequence) do
      g:led(step, value, 10)
    end
    g:refresh()
    return
  end


  if state.mode == 'motion' then
    for i=1,16 do
      g:led(i, state.motion.selectedTrack, 5)
    end
    if state.motion.selectedNote then
      g:led(state.motion.selectedNote[1], state.motion.selectedNote[2], 10)
    end
  end

  for i=1,8 do
    g:led(i,8,3)
  end

  for step, value in pairs(state.sequences[state.activeSequence]) do
    for y, triggered in pairs(value) do
      if step == state.position then
        g:led(step, y, 5)
      end
      if triggered == 1 then
        g:led(step, y, 10)
      end
    end
  end

  g:led(state.meta.sequence[state.meta.position], 8, 5)
  g:led(state.activeSequence, 8, 10)
  g:refresh()
end

function redraw()
  screen.clear()
  screen.font_face(1)
  screen.font_size(8)

  -- Draw play/pause
  screen.move(10,10)
  if state.clock then
    screen.text('playing')
  else
    screen.text('paused')
  end

  -- Draw BPM
  screen.move(90, 10)
  screen.text("BPM: " .. params:get("bpm"))

  -- Draw Mode
  screen.font_face(10)
  screen.font_size(20)
  screen.move(10, 48)
  screen.text(state.mode)

  screen.update()
end
