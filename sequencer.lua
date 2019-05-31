-- simple sequencer
-- v 0.1.0
--
-- requires a grid
-- press any key in rows 1-6
-- to set a step
--
-- row 7 jumps to step
-- row 8 is a pattern bank
--
-- Knob 1 to change mode
-- Knob 2 to change pitch
-- Knob 3 to change bpm
--
-- Hold key 1 to clear pattern
-- key 2 to pause
-- key 3 to toggle record
--
-- While recording:
--     press last 6 keys in row 8
--     turn knob 2 to record pitch
--
-- While in meta mode:
--     press keys in row 1-8 to set pattern
--     Knob 2 to change sequence length

engine.name = 'Ack'
local ack = require'ack/lib/ack'
local g = grid.connect()
local BeatClock = require 'beatclock'
local clock = BeatClock.new()
local UI = require "ui"

local clock = metro.init()

local state = {
  pitchPositions = {
    1, 1, 1, 1, 1, 1
  },
  t = 0,
  sequences = {},
  bpm = 80,
  activeSequence = 1,
  meta = {
    sequence = {1},
    position = 1,
  },
  activeTrack = 1,
  mode = UI.Pages.new(1,2), -- possible modes: sequence, motion
  clock = true,
  recording = false,
  recordingPosition = 0,
  position = 1,
  queuedPosition = nil,
  copying = 0
}

function generatePitches(num)
  local pitches = {}
  for k=1,96 do
    table.insert(pitches, num)
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
        table.insert(step, {trig=0, pitch=generatePitches(1)})
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
    end

    if state.recordingPosition == state.position then
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
    if state.mode.index == 1 and state.activeTrack == i and state.recording == true then
      step[i].pitch[state.t] = state.pitchPositions[state.activeTrack]
    end
    params:set(param, step[i].pitch[state.t])
  end

end

------ EVENTS ------

function g.key(x, y, z)
  if state.mode.index == 2 then
    if z == 1 then
      setMetaStep(x, y)
    end
    return
  end

  if state.mode.index == 1 then
    if y <= 6 and z == 0 then
      toggleStep(x, y)
      setActiveTrack(y)
    end

    if y == 8 and z == 1 and x > 10 then
      recordNote(x-11, y)
      setActiveTrack(x-10)
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
  if (state.mode.index == 2) then
    if n == 2 then
     changeMetaLength(direction)
    end
  end
  if state.mode.index == 1 then
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
  state.recordingPosition = state.position - 1
  redraw()
end

function recordNote(x)
  setActiveTrack(x+1)
  params:set(state.activeTrack..'_speed', state.pitchPositions[state.activeTrack])
  engine.trig(x)
  if state.recording then
    local step = state.sequences[state.activeSequence][state.position][x + 1]
    step.pitches = generatePitches(state.pitchPositions[x+1])
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
      {trig=0, pitch=generatePitches(1)},{trig=0, pitch=generatePitches(1)},{trig=0, pitch=generatePitches(1)},
      {trig=0, pitch=generatePitches(1)},{trig=0, pitch=generatePitches(1)},{trig=0, pitch=generatePitches(1)}
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

function setActiveTrack(track)
  state.activeTrack = track
  redraw()
end

function setPitch(direction)
  local pitches = state.pitchPositions
  pitches[state.activeTrack] = pitches[state.activeTrack] + direction/20
  redraw()
end

function copySequence(x)
  if state.copying == 0 then return end
  for step, value in pairs(state.sequences[state.copying]) do
    for sample, note in pairs(value) do
      local pitch = {}
      for i = 1, 96 do
        table.insert(pitch, note.pitch[i])
      end
      state.sequences[x][step][sample] = {trig=note.trig, pitch=pitch}
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

  if state.mode.index == 2 then
    for i=1,8 do
      g:led(state.meta.position, i, 5)
    end
    for step, value in pairs(state.meta.sequence) do
      g:led(step, value, 10)
    end
    g:refresh()
    return
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
    screen.font_size(16)
    screen.move(0, 25)
    screen.text('TRACK:' .. state.activeTrack)
    screen.move(0, 38)
    screen.text('SPEED:' .. state.pitchPositions[state.activeTrack])
  -- META MODE
  else
    screen.text('META')
  end

  state.mode:redraw()
  screen.update()
end

function drawRecording()
  if state.recording then
    screen.move(0,60)
    screen.level(16)
    screen.font_size(24)
    screen.text('RECORDING')
    screen.level(10)
  end
end
