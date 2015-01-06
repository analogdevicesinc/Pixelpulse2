## Pixelpulse2

Pixelpulse is a powerful user interface for visualizing and manipulating signals while exploring systems attached to affordable analog interface devices, such as Analog Devices' ADALM1000 or the Nonolith Labs' CEE.

Fully cross-platform using the Qt5 graphics toolkit and OpenGL accelerated density-gradiated rendering, it provides a powerful and accessible tool for initial interactive explorations. 

Intuitive click-and-drag interfaces make exploring system behaviors across a wide range of signal amplitudes, frequencies, or phases a trivial exercise. Just click once to source a constant voltage or current and see what happens. Choose a function (sawtooth, triangle, sinusoidal, square) - adjust parameters, and make waves.

Zoom in and out  with your scroll wheel or multitouch gestures (on supported platforms). Hold "Shift" to for Y-axis zooming.

Click and drag the X axis to pan in time.

### Getting Pixelpulse2

To build from source on Linux / OSX:

    git clone --recursive https://github.com/signalspec/pixelpulse2
    git checkout qmake
    git submodule update
    mkdir build
    qmake ..
    make -j4
    ./pixelpulse2

To get an up-to-date binary build for Windows:

 * Navigate to the [AppVeyor](https://ci.appveyor.com/project/kevinmehall/pixelpulse2/build/artifacts) page, download the 'release' .exe.
 * Download the dependency package from [third-party hosting](https://kevinmehall.net/tmp/pixelpulse2_r3.zip)
 * Extract the dependency package and overwrite the included pixelpulse2.exe with the release image downloaded from AppVeyor.
 * With a M1K attached, double-click the executable to launch Pixelpulse.


