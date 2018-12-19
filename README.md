# Jared's Norns Scripts

These are scripts that I'm playing around with to make instruments on the
[monome norns](https://monome.org/norns/).

### Scripts
- **sequencer.lua**: a simple sequencer that I'm using to learn and experiment.
  Borrows liberaly from tehn's
  [playfair](https://github.com/monome/dust/blob/master/scripts/tehn/playfair.lua) 

### Syncing

While in development I prefer to edit these files on my local machine and then
use `rsync` to sync them over to the norns. There's a one-line script,
[sync.sh](./sync.sh) for doing this. 

If you want to use it just remember to use the right IP for your norns!

In the future I want to expand this to also send the message on the norns to
reload the given script. I was offered some advice
[here](https://github.com/monome/norns/issues/602)
