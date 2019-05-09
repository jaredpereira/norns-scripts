-- jss (jared's simple sequencer)
-- v 0.0.3
--
-- requires a grid
-- press any key in rows 1-6
--
-- row 7 jumps to step
-- row 8 is a pattern bank
--
-- Knob 1 to change mode


engine.name = 'Ack'
local ack = require'ack/lib/ack'
local g = grid.connect()
local BeatClock = require 'beatclock'
local clock = BeatClock.new()
local UI = require "ui"

local clock = metro.init()

local state = {
  t = 0,
  sequences = {},
  bpm = 80,
  activeSequence = 1,
  meta = {
    sequence = {1},
    position = 1,
  },
  motion = {
    pitchPos = 1,
    track = 1,
    notes = {}
  },
  mode = UI.Pages.new(1,3), --possible modes: sequence, meta, motion
  clock = true,
  recording = false,
  position = 1,
  queuedPosition = nil,
  copying = 0
}

function generatePitches()
  local pitches = {}
  for k=1,96 do
    table.insert(pitches, 1)
  end
  return pitches
end

function init()
  -- BeatClock
  clock.time = 15/(state.bpm * 96)
  clock.event = countStep

  clock:start()

  -- Ack setup
  ack.add_params()
  params:read()
  params:bang()

  -- State
  for i=1,8 do
    local sequence = {}
    for i=1,16 do
      local step = {}
      for j=1,6 do
        table.insert(step, {trig=0, pitch=generatePitches()})
      end
      table.insert(sequence, step)
    end
    table.insert(state.sequences, sequence)
  end
end

function countStep(t)
  state.t = (t % 96) + 1
  if t%96 == 0 then
    if state.position == 16 then
      state.meta.position = (state.meta.position % #state.meta.sequence) + 1
      state.recording = false
    end
    if state.queuedPosition then
      state.position = state.queuedPosition
      state.queuedPosition = nil
    else
      state.position = (state.position % 16) + 1
    end
    redraw()
    grid_redraw()

    local playingSequence = state.meta.sequence[state.meta.position]
    local step = state.sequences[playingSequence][state.position]

    engine.multiTrig(step[1].trig, step[2].trig, step[3].trig, step[4].trig, step[5].trig, step[6].trig, 0 ,0)
  end

  for i=1,6 do
    local playingSequence = state.meta.sequence[state.meta.position]
    local step = state.sequences[playingSequence][state.position]
    local param = tostring(i) .. '_speed'
    if state.mode.index == 2 and state.motion.track == i and state.recording == true then
      step[i].pitch[state.t] = state.motion.pitchPos
    end
    params:set(param, step[i].pitch[state.t])
    print(step[i].pitch[state.t])
  end

end

------ EVENTS ------

function g.key(x, y, z)
  if state.mode.index == 3 then
    if z == 1 then
      setMetaStep(x, y)
    end
    return
  end

  if state.mode.index == 1 then
    if y <= 6 and z == 0 then
      toggleStep(x, y)
    end

    if y == 8 and z == 1 and x > 10 then
      recordNote(x-11, y)
    end
  end

  if state.mode.index == 2 then
    if y <= 6 and z == 1 then
      setSelectedTrack(y)
      addSelectedNote(x)
    elseif y<=6 and z ==0 then
      removeSelectedNote(x)
    end
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

function key(n, z)
  if n == 1 and z == 1 then
    clearPattern()
  end

  if n == 2 and z == 1 then
    toggleClock()
  end

  if n == 3 and z == 1 then
    toggleRecording()
  end
end

function enc(n, direction)
  if n == 3 then
    setBPM(direction)
  end
  if (state.mode.index == 3) then
    if n == 2 then
     changeMetaLength(direction)
    end
  end
  if state.mode.index == 2 then
    if n == 2 then
      setPitch(direction)
    end
  end

  if n == 1 then
    changeMode(direction)
  end
end

------ ACTIONS ------

function toggleStep(x,y)
  local step = state.sequences[state.activeSequence][x][y].trig
  state.sequences[state.activeSequence][x][y].trig = (step + 1) % 2
  grid_redraw()
end

function toggleRecording()
  state.recording = state.recording == false
  redraw()
end

function recordNote(x)
  engine.trig(x)
  if state.recording then
    local step = state.sequences[state.activeSequence][state.position][x + 1]
    step.trig = 1
  end
end

function setPosition(x)
  state.queuedPosition = x
  grid_redraw()
end

function toggleClock()
  if state.clock then
    clock:stop()
  else
    clock:start()
  end
  state.clock = state.clock == false
  redraw()
end

function clearPattern()
  for i=1,16 do
    state.sequences[state.activeSequence][i] = {
      {trig=0, pitch=generatePitches()},{trig=0, pitch=generatePitches()},{trig=0, pitch=generatePitches()},
      {trig=0, pitch=generatePitches()},{trig=0, pitch=generatePitches()},{trig=0, pitch=generatePitches()}
      }
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

function changeMode(direction)
  state.mode:set_index_delta(util.clamp(direction, -1, 1), false)
  redraw()
  grid_redraw()
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
    if length < 16 then
      state.meta.sequence[length + 1] = 1
    end
  elseif length > state.meta.position then
      state.meta.sequence[length] = nil
  end
  grid_redraw()
end

function setSelectedTrack(track)
  state.motion.track = track
  redraw()
end

function addSelectedNote(note)
  table.insert(state.motion.notes, note)
  grid_redraw()
  redraw()
end

function removeSelectedNote(note)
  for key, value in pairs(state.motion.notes) do
    if value == note then
      table.remove(state.motion.notes, key)
    end
  end
  grid_redraw()
  redraw()
end

function setPitch(direction)
  -- local playingSequence = state.meta.sequence[state.meta.position]
  -- local sequence = state.sequences[playingSequence]

  state.motion.pitchPos = state.motion.pitchPos + direction/20

  -- if #state.motion.notes > 0 then
  --   for key, value in pairs(state.motion.notes) do
  --     local note = sequence[value][state.motion.track]
  --     note.pitch[state.t] = note.pitch[state.t] + (direction/20)
  --   end
  --   redraw()
  --   return
  --  end

  -- local step = sequence[state.position][state.motion.track]
  -- if state.recording then
  --   local param = tostring(state.motion.track) .. '_speed'
  --   step.pitch[state.t] = step.pitch[state.t] + (direction/20)
  --   params:set(param, step.pitch[state.t])
  -- end
  redraw()
end

function copySequence(x)
  if state.copying == 0 then return end
  for step, value in pairs(state.sequences[state.copying]) do
    for sample, note in pairs(value) do
      state.sequences[x][step][sample] = {trig=note.trig, pitch=note.pitch}
    end
  end
end

function setBPM(x)
  state.bpm = state.bpm + x
  clock.time = 15/(state.bpm * 96)
  redraw()
end


------- UI -------

function grid_redraw()
  g:all(0)

  if state.mode.index == 3 then
    for i=1,8 do
      g:led(state.meta.position, i, 5)
    end
    for step, value in pairs(state.meta.sequence) do
      g:led(step, value, 10)
    end
    g:refresh()
    return
  end


  if state.mode.index == 2 then
    for i=1,16 do
      g:led(i, state.motion.track, 5)
    end
    if #state.motion.notes > 0 then
      for key, value in pairs(state.motion.notes) do
        g:led(value, state.motion.track, 10)
      end
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
      if triggered.trig == 1 then
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
  screen.level(10)
  screen.font_face(1)
  screen.font_size(8)

  screen.move(0, 8)
  screen.line(128, 8)
  screen.stroke()

  -- Draw BPM
  screen.move(90, 5)
  screen.text("BPM: " .. state.bpm)

  -- Draw Mode
  screen.move(5, 5)

  -- SEQUENCE MODE
  if state.mode.index == 1 then
    screen.text('SEQUENCE')
    drawRecording()
  -- MOTION MODE
  elseif state.mode.index == 2 then
    screen.text('MOTION')

    drawRecording()
    local speed = params:get(state.motion.track .. '_speed')
    if #state.motion.notes > 0 then
      local playingSequence = state.meta.sequence[state.meta.position]
      speed = state.sequences[playingSequence][state.motion.notes[1]][state.motion.track].pitch[state.t]
    end

    screen.move(10, 48)
    screen.text('SPEED: ' .. speed)

  -- META MODE
  else
    screen.text('META')
  end

  state.mode:redraw()
  screen.update()
end

function drawRecording()
  if state.recording then
    screen.move(10,40)
    screen.font_size(15)
    screen.text('RECORDING')
    screen.font_size(8)
  end
end
