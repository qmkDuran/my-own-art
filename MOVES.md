# Moves

Every move both creatures can learn. Generated from `game/data/moves.json` by `python3 -I tools/moves_doc.py`;
edit the JSON, not this file. Each creature takes four into a fight (LMB, RMB, Q, E), picked on the loadout
screen. **Baby** fights only allow moves marked Baby; **Grown** allows all of them. Every move has a visible
wind-up and a cooldown, and a counter (its tit for tat).


## Attack

| Move | Effect | Cost | Counter (tit for tat) | Min level | Cooldown |
| --- | --- | --- | --- | --- | --- |
| **Snap** | A quick bite with a short lunge. | Commits you for half a second. | The jaw glow and head pull are easy to read; roll back. | Baby | 1.35 s |
| **Rush Strike** | A long dash that ends in a strike. | Long recovery if it misses. | Sidestep the straight line; it overshoots. | Grown | 2.6 s |
| **Leaping Strike** | Pounce through the air onto the target; clears logs. | Airborne: cannot steer once launched. | Step aside while it is in the air. | Baby | 2.1 s |
| **Tail Sweep** | A full turn that hits all around and knocks back. | Short reach, light damage. | Stay just out of reach. | Baby | 1.9 s |
| **Ram** | A head-down charge that staggers. | Slow wind-up, head lowered and obvious. | Roll sideways out of the charge line. | Baby | 2.2 s |
| **Rake** | A fast, light claw swipe. | Little damage. | Trade it for a heavier hit. | Baby | 0.9 s |
| **Glob** | A slow glob of spit aimed at the crosshair. | Slow: it can be dodged or blocked by trees. | Break line of sight behind a trunk. | Baby | 2.5 s |
| **Cinder Spit** | A burning glob that sets tall grass alight. | Burns your own hiding spots too. | Water douses the fire; burnt grass regrows. | Baby | 2.8 s |
| **Spray Jet** | A fast jet of water: puts out fire, turns soil to mud. | Shorter reach. | Mud slows whoever walks through it, you too. | Baby | 2.2 s |
| **Seed Scatter** | Three seeds in a fan. | Each seed is weak; spread misses at range. | Get close or far; the fan only covers mid range. | Grown | 3.0 s |
| **Mud Lob** | A heavy ball of mud that slows what it hits. | Slow ball, easy to see. | Dodge it and the slow never lands. | Baby | 2.8 s |
| **Thorn Dart** | A quick thorn, hard to dodge. | Light damage. | Cover still stops it. | Grown | 1.7 s |
| **Ground Thump** | Slam the ground: a shockwave hits everything around, even burrowers. | Rooted while winding up; very loud. | Back out of the ring before it lands. | Grown | 3.4 s |
| **Twirl** | Spin on the spot, hitting all around. | Short reach. | Keep your distance until it ends. | Baby | 2.6 s |

## Movement

| Move | Effect | Cost | Counter (tit for tat) | Min level | Cooldown |
| --- | --- | --- | --- | --- | --- |
| **Leap** | Jump onto rocks, logs and low ledges. | Landing is noisy. | Airborne creatures cannot roll. | Baby | 1.6 s |
| **Spring** | A big standing jump up onto high ledges. | Rooted while crouching for it. | The crouch is a clear tell. | Grown | 3.4 s |
| **Burrow** | Dig into soft ground, travel under it, pop up with a hit (use again). | Only in soft soil; slow to dig in. | A rumbling dust trail and noise show where it goes; a ground thump hits it. | Baby | 6.0 s |
| **Climb** | Climb a marked tree and hide in its crown (use again to drop). | Stuck in place while up there. | Climbing shakes the leaves; senses and echo find it. | Baby | 4.0 s |
| **Glide** | A hop into a long, slow glide; best from high ground. | Floaty and easy to hit in the air. | Spit where it will land. | Grown | 3.4 s |
| **Submerge** | Slip under the water of the stream or pond and swim hidden (use again to surface). | Slow, cannot attack underwater. | A line of bubbles follows it. | Baby | 4.0 s |
| **Scamper** | A burst of speed. | Very loud footsteps while it lasts. | Easy to hear coming. | Baby | 6.0 s |

## Defensive

| Move | Effect | Cost | Counter (tit for tat) | Min level | Cooldown |
| --- | --- | --- | --- | --- | --- |
| **Bark Skin** | Toughen up: half damage for a while. | Moves slower while it lasts. | Reposition or wait it out. | Baby | 10.0 s |
| **Ward** | A short shell that blocks every hit. | Very short, long cooldown. | Feint, then strike after the shell fades. | Baby | 10.0 s |
| **Sidestep** | A quick short hop to the side, safe from hits while it lasts. | Shorter than a roll. | Aim slightly to the side it favours. | Baby | 1.1 s |
| **Smoke Puff** | A cloud of smoke to hide in, anywhere. | Everyone can see where the cloud is. | Spit or thump into the cloud. | Grown | 12.0 s |
| **Tuck** | Curl up: take little damage and cannot be staggered. | Cannot move while tucked. | Walk away and set up; it wasted its turn. | Baby | 7.0 s |

## Buff

| Move | Effect | Cost | Counter (tit for tat) | Min level | Cooldown |
| --- | --- | --- | --- | --- | --- |
| **Quickening** | Faster for a while. | Louder steps while it lasts. | Listen: it cannot sneak up on you. | Baby | 12.0 s |
| **Bristle** | Hits harder for a while. | Stands still bristling for most of a second. | Punish the wind-up, or keep away until it fades. | Baby | 12.0 s |
| **Steady Eye** | The next hit lands as a critical (x1.8). | A full second standing still; gives your hiding place away. | Ward or roll the next big hit. | Grown | 10.0 s |
| **Lick Wounds** | Patch yourself up a little. | Over a second standing still, long cooldown. | Interrupt it: any hit during the wind-up cancels the heal. | Baby | 20.0 s |

## Debuff

| Move | Effect | Cost | Counter (tit for tat) | Min level | Cooldown |
| --- | --- | --- | --- | --- | --- |
| **Kick Dirt** | Dirt in the eyes: the target can barely see for a moment. | Close range, narrow cone. | Back off until your eyes clear; it cannot follow what it cannot see either if you hide. | Baby | 6.0 s |
| **Menace** | A threatening growl: nearby foes hit softer for a while. | Very loud: everyone knows where you are. | Fall back and let it wear off. | Baby | 9.0 s |
| **Sticky Sap** | Sticky sap that slows what it hits. | Barely hurts. | Cover stops it like any spit. | Baby | 6.0 s |
| **Dizzy Dance** | A swaying dance that confuses: movement goes the wrong way. | Long, obvious wind-up up close. | Step out of range during the dance. | Grown | 10.0 s |

## Sense

| Move | Effect | Cost | Counter (tit for tat) | Min level | Cooldown |
| --- | --- | --- | --- | --- | --- |
| **Keen Ears** | For a while every sound nearby is pinged, from much further away. | Only sounds: a still, quiet creature stays hidden. | Sneak and hold still. | Baby | 10.0 s |
| **Scent Trail** | Sniff out where the target walked in the last few seconds. | Standing still sniffing; the trail is a few seconds old. | Double back or take to the water. | Baby | 11.0 s |
| **Echo Pulse** | A pulse that reveals every hidden creature nearby for a moment. | Reveals you as well, loudly. | When it pulses, you see it too: strike first. | Grown | 12.0 s |

## Terrain

| Move | Effect | Cost | Counter (tit for tat) | Min level | Cooldown |
| --- | --- | --- | --- | --- | --- |
| **Bramble Wall** | Grow a wall of brambles in front: blocks movement, sight and spit. | Blocks your own shots too. | Fire burns it down; go around. | Baby | 11.0 s |
| **Sprout Cover** | Grow a patch of tall grass at your feet to hide in. | Growing it is seen and heard nearby. | Burn it, or check the new grass first. | Baby | 14.0 s |
| **Kindle** | Set the grass all around alight. | Burns your own cover. | Water puts it out. | Grown | 9.0 s |
