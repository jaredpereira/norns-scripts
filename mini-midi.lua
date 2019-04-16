engine.name = 'PolyPerc'

local arpState = {
  notes = {},
  mode = "up",
}

function init()
  m = midi.connect()
  m.event = handle_midi
  counter = metro.init()
  counter.time = 0.5
  counter.count = -1
  counter.event = arpeggiate
  counter:start()
  tab.print(counter)
end

function playNote(note)
	engine.amp(1)
   	engine.hz((440 / 32) * (2 ^ ((note - 9) / 12)))
end

function addArpNote(target_note)

	for idx, note in pairs(arpState.notes) do
		-- Make sure we only add unique notes
		if note == target_note then
			return
		end
	end 

	table.insert(arpState.notes, target_note)
	print('Added note:', target_note)
end

function removeArpNote(target_note)
	for idx, note in pairs(arpState.notes) do
		if note == target_note then
			table.remove(arpState.notes, idx)
			print('Removed note: ', target_note, idx)
		end
		print('Current idx, note: ', idx, note)
	end 
end

function arpeggiate(count)
	notes = arpState.notes
	print("---------------")
	tab.print(notes)

	if #notes == 0 then return end

	--table.sort(notes)
	playNote(notes[(count % (#notes))+1])
end

function handle_midi(data)
  msg = midi.to_msg(data)
  --tab.print(msg)
  velocity = data[3]
  if msg.type == 'note_on' then
  	--playChord(msg.note, playNote)
	addArpNote(msg.note)
  end

  if msg.type == 'note_off' then
	removeArpNote(msg.note)	
  end

end

function setArpMode(mode)
end

function enc(encoder, direction)
	if encoder == 2 then
		newTime = counter.time - direction/100
		if newTime <= 0 then newTime = 0.01 end
		if newTime > 10 then newTime = 10 end
		counter.time = newTime
	end
end
