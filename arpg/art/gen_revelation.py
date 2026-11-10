"""PAID (3 x 10 gens, 16 variants at 64 px each): three enemies from Revelation, evil-looking but never satanic
imagery or gore. Same style anchor as the other demons; side view facing left (mirrored for right). Run from heaven/.
  locust  - Rev 9:7-10        frog    - Rev 16:13-14        firehorse - Rev 9:17-19"""
import sys; sys.path.insert(0, 'tools')
from plh import *
COMMON = (" Menacing dark horror creature for a pixel art action game, full body, side view facing left, glowing eyes, "
          "sharp silhouette, dark palette, not cartoony, not cute. No blood, no gore, no symbols, no text. "
          "Clean pixel art game sprite, dark outline")
WHAT = {
    "locust": ("A demonic locust from the Abyss shaped like a war horse prepared for battle, large dark insect wings raised, "
               "a crown-like crest of gold on its head, a gaunt pale human-like face with long dark hair, lion fangs, "
               "chest of dark iron scales like a breastplate, a curved scorpion tail with a stinger, iron grey and black "
               "with ember-orange eyes."),
    "frog": ("An impure spirit that looks like a large frog, crouched to leap, made of sickly green and black shadow with "
             "smoky wisps trailing from its back, a wide mouth leaking dark smoke, bulging glowing yellow-green eyes, "
             "long thin clawed fingers."),
    "firehorse": ("A demonic war horse with the head of a lion and a dark mane, rearing slightly, black hide with fiery red, "
                  "dark blue and yellow armour plates, fire and dark smoke pouring from its open jaws, its tail a black "
                  "serpent with a snake head, ember-red eyes, no rider."),
}
for name in sys.argv[1:] or WHAT:
    gimg(f"arpg_{name}", WHAT[name] + COMMON, 64, 64, seed={"locust": 907, "frog": 1613, "firehorse": 917}[name])
