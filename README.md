AdvancedCharacter2D
===================

This is a (work in progress) pretty much self-contained and feature complete 2D character (platform only supported at the moment)
class for Godot. Just drop it into your game, add an AnimatedSprite2D to it with your character animations on it, and use the
inspector to configure it with actions and other settings. It handles all the switch of animations, collisions, raycasting for
both observing objects and attacking enemies, jumping, falling, sound effects....

All without writing a single line of code.

Installing
=============

1. Clone this repo into your game somewhere.
2. Add an AdvancedCharacter2D node to your game tree
3. Add an AnimatedSprite2D to that new node as a child.
4. Add your animations for the character to that sprite
5. Configure the AdvancedCharacter2D node as below:

Configuring
===========

Movement Settings
-----------------

This section defines basic motion settings for your character:

* Movement Type: Select Platform or World. Only Platform is implemented at the moment. It defines how the character moves in the game.
* Walk Speed: How fast the character walks normally
* Run Speed: How fast the character runs when the run modifier is held down
* Crawl Speed: How fast the character crawls (or sneaks, or creeps) when the crawl modifier is held down
* Jump Power: How high the character jumps.
* Fall Sound Threshold: How fast the character has to fall before they play the fall sound and the "high impact" landing sound

Movement Actions
----------------

This defines which input actions are associated with which operation within the character. Assign input actions (as defined in the 
project settings) to the different operations of movement, jumping and attack.

Movement Modifiers
------------------

Defines the input actions which are used as movement modifiers for running and crawling.

Raycast
-------

Two ShapeCast2D objects are used to detect items around your character. One is the "observation" which is what the character can see in front of them.
The other is the "attack" which is what they are attacking with their weapon.  Here you define how far in front of the character the two rays extend.

Animation
---------

Basic settings for the animation of the character, including what sound to make when they land hard, what object the AnimatedSprite2D is, and which
direction the character starts facing.  Make sure to assign your AnimatedSprite2D here so that the class knows what to animate.

Actions
-------

This is the complex part and the bit where all the magic happens.  Internally there are a LOT of actions the character can do, including moving in different
directions and at different speeds, attacking, jumping, falling, etc. These actions all need defining in this section to get your character to actually
do things.  Add an element for each action you want to be able to perform.  Within each action configure:

* Type: What type of action this is - walking left, jumping right, attacking left, etc. 
* Hitbox Offset: The offset from the center of the sprite for this action's hitbox. Used for collision detection.
* Hitbox: The shape of the hitbox for this action. Different actions have different animations, and different animations can have different
  hitbox requirements. To get this set right you may want to look at the "Debug" section below.
* Animation Name: The name of the animation for this action in the AnimatedSprite2D
* Flip H / Flip V: Whether or not to flip the animation horizontally or vertically for this action. This lets you use the same animation for two different
  actions, one facing left and one facing right.
* Audio File: The sound effect to play for this action.

Debug
-----

This section lets you pick which action is currently being displayed in the editor. It allows you to arrange your hitbox visually.  The Editor Action number
corresponds to the array entry number in the Actions list.

Disclaimer
==========

THIS IS ONLY A WORK IN PROGRESS AT THE MOMENT. DON'T EXPECT IT TO ACTUALLY WORK, AND ANYTHING THAT DOES HAPPEN TO WORK, DON'T EXPECT IT TO EITHER KEEP WORKING
OR TO KEEP WORKING IN THE SAME WAY. THINGS ARE BOUND TO CHANGE AS THE CODE EVOLVES.

Feel free to learn from this code though.....

Contributing
============

Contributions (through Github pull requests) and suggestions (find me on the Pirate Software #Godot Discord channel) are more than welcome. I am pretty new
to Godot and there are lots of things that I don't yet quite understand, so this is a learning project for me as well.
