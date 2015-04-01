# Leap Recognizer v1.0

This is a gesture and pose recognition system for the [Leap Motion](https://www.leapmotion.com/) written in Objective-C.

It was part of [my master thesis work](http://www.slideshare.net/daqo/masters-thesis-proposal-david-qorashi) focused on using hand gestures to navigate drones.

The system uses a $P Point-Cloud Recognizer for geometric template matching.

You can define any kind of gesture in the application, but in the UI I just show the labels for Right, Left, Up, Down, Forward, Back and Hover gestures.

## Usage
First you need to define gestures and train the system about them. After the training is completed, the system can categorize the new gestures based on the training set.

## Demo
Here is the mirror image for recognizing a Yaw Left gesture. As you see the system recognized that as a left.

![ScreenShot](./images/yaw_left_image.png)

## Author
David Qorashi

Contact: qorashis AT mail.gvsu.edu



[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/daqo/leap-recognizer/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

