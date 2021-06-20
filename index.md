---
layout: projects
---

# Code

## Other Places

Code in other places:

* [GitHub repositories](https://github.com/osteele)
* [OpenProcessing sketches](https://openprocessing.org/user/201396/?view=sketches)
* [Observable notebooks](https://observablehq.com/@osteele)

## Topics

### [p5.js](https://www.notion.so/Oliver-s-p5-js-Resources-385707291d5f4a6db4a590f95f8c5a94)

[p5.layers](https://osteele.github.io/p5.layers/) is a library that adds
`beginLayer()` and `endLayer()` functions, that simplify the use of p5.js
Graphics objects and redirect `fill()`, `rect()` etc. to the current "layer"
(Graphics). See [these examples](https://osteele.github.io/p5.layers/examples/).

[Examples](https://www.notion.so/p5-js-Examples-18214cd693bd43919d9d0c4cded0b05f)
of topics that have come up during student projects: controlling gif animation,
cross-fading audio, slicing sketches, etc.

[Step-by-step
tutorials](https://www.notion.so/55581dbef83f40e3a386ddc6be1bbee8?v=692f92adea66460c8d8c4997af88431d).
These differ from the examples in that they take several steps to build up to a
solution. They are intended to teach an understanding of various concepts along
the way to the solution, rather than to present it whole sale.

Starter templates for [GitHub](https://github.com/osteele/p5-template) and
[Glitch](https://glitch.com/edit/#!/cclab-p5js-template). These use a CDN.

[p5.js sketches](https://openprocessing.org/user/201396/?view=sketches) on OpenProcessing.org

[React integration](https://github.com/osteele/p5-react) defines a React
component that renders a p5 sketch. One application can include multiple sketches.

### [PoseNet](https://www.notion.so/PoseNet-ded646bc5c1a4b99bf2885ad891937d2)

[p5pose](https://github.com/osteele/p5pose) is a starter template for p5.js +
[ml5.js](https://learn.ml5js.org/#/reference/posenet). I prefer it to the
official starter because I prefer for my students to use the [for…of
statement](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/for...of).

[p5pose-recorder](https://github.com/osteele/p5pose-recorder) ([online
version](https://osteele.github.io/p5pose-recorder/)) records PoseNet data into
a JSON file (or set of files). Before saving the file, the user can use a
built-in timeline editor to trim the beginning and end, which tend to includes
poses from when the user backed up from the webcam after starting the program,
and from when they approached the webcam again after creating the pose.

[p5pose-playback](https://github.com/osteele/p5pose-playback) ([online
demo](https://osteele.github.io/p5pose-playback/)) adds a menu to (my version
of) the ml5.js PoseNet starter. Use the menu to switch between the webcam, and
PoseNet JSON datasets that were recorded with p5pose-recorder (above).

[p5pose-optitrack](https://github.com/osteele/p5pose-optitrack) presents data
from an OptiTrack motion capture setup as though it were PoseNet data. Students
who have written a sketch to work with PoseNet data can run it on
OptiTrack data by changing a line of code.

In some circumstances, PoseNet runs faster when the sketch that is running
PoseNet is different from the page that is running the animation. [Here's
how](https://github.com/osteele/posenet-pubsub).

### [Physical Computing](https://www.notion.so/Physical-Computing-6eeee0efa9354212b76f501b3fbc972d)

[imu-tools](https://github.com/osteele/imu-tools) is a set of tools for
sending IMU data from an ESP32 and receiving it on a command-line program or in
a web application. It includes the source for an npm package that can be used in
a web application to receive data via MQTT (any browser) or Bluetooth (Google
Chrome).

[Arduino-BLE-IMU](https://github.com/osteele/Arduino-BLE-IMU) is
firmware that runs on an ESP32 and relays BNO055 data wirelessly to computer via
MQTT (over WiFi) and/or Bluetooth.

[imu-client-examples](https://github.com/osteele/imu-client-examples) is
a set of examples that use relayed wireless IMU data in various ways: to animate
one or more Stanford bunnies, and to graph the data.

### [Education Tools](https://www.notion.so/Education-Tools-and-Materials-7c62990392284aab934c32b45ec9a99c)

#### For Students

[Map Explorer](https://osteele.github.io/map-explorer/)
([source](https://github.com/osteele/map-explorer)) is an interactive
visualization of the `map` function in Arduino, Processing, and p5.js.

[PWM Explorer](https://osteele.github.io/pwm-explorer/)
([source](https://github.com/osteele/pwm-explorer)) is an interactive
visualization of Pulse Width Modulation (PWM).

#### For Educators

Tools to manage multiple repositories, and to track and collate assignments that
are distributed as Jupyter notebooks:

[Callgraph](https://github.com/osteele/callgraph) runs in a Jupyter notebook. It
adds call graphs to functions.

[Section Wheel](http://selection-wheel.underconstruction.fun/)
([source](https://github.com/osteele/selection-wheel)) spins a wheel to select a
student (or team) name from a list of names. Repeat until all the names have
been chosen. I use it to select presentation order.

[NameShuffler](https://github.com/osteele/NameShuffler) performs the same
function, but with an animated list instead of a wheel. It is written as a
Processing sketch.

[multiclone](https://github.com/osteele/multiclone) clones all the forks of a
repository, or all the copies of a GitHub Classroom assignment. It's very fast.
It renames the files to incorporate the students' GitHub handles into the local
project directory names. It creates a mr configuration file, so that you can
pull (or push) all the repositories with as single command.

[nbcollate](https://github.com/osteele/nbcollate) combines Jupyter notebooks
(one per student) into a single notebook that is collects all the cells that
follow a header cell into a section. I use it for reviewing and sometimes
presenting student work.

[assignment-dashboard](https://github.com/osteele/assignment-dashboard) is for
situations where students submit their assignments as Jupyter notebooks on
GitHub. It shows a table of which students have submitted which notebooks on
which dates. You can drill in to see a table of which students have answered
which questions.

## GitHub Repository Browser

_Generated from GitHub metadata. Under construction. [About](/colophon)._
