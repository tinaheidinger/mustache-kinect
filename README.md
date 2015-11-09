# Project 3 - Kinect Hacking

## Software

We used Processing 2 with SimpleOpenNI on OS X.

## Project Description

We developed a game where mustaches are drawn onto each player’s face and scale depending on the player’s distance from the sensor. Each player is equipped with a razor that can be used to shave the mustache. The environment reminds of a bathroom mirror. The player can grab the razor from its storage and put it back afterwards.

## Sources

* Skeleton tracking: http://blog.3dsense.org/programming/programming-for-kinect-4-kinect-app-with-skeleton-tracking/
* Tracking one hand as a part of the skeleton: https://gist.github.com/atduskgreg/1364198
* Displaying images: https://processing.org/reference/image_.html
* Image Transparency: https://processing.org/reference/tint_.html

## Custom-built parts

* Mirror frame
* Drawing the mustache onto each player's face
* Drawing the razor onto each player's right hand
* Collision detection between razor and mustache
* Fading out the mustache on collision with razor
* Collision detection between razor and razor storage
* Taking the razor from the storage and putting it back
* Redisplaying the mustache every 5 seconds
