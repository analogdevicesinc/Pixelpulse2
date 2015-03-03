## Pixelpulse2

Pixelpulse is a powerful user interface for visualizing and manipulating signals while exploring systems attached to affordable analog interface devices, such as Analog Devices' ADALM1000 or the Nonolith Labs' CEE.

Fully cross-platform using the Qt5 graphics toolkit and OpenGL accelerated density-gradiated rendering, it provides a powerful and accessible tool for initial interactive explorations.

Intuitive click-and-drag interfaces make exploring system behaviors across a wide range of signal amplitudes, frequencies, or phases a trivial exercise. Just click once to source a constant voltage or current and see what happens. Choose a function (sawtooth, triangle, sinusoidal, square) - adjust parameters, and make waves.

Zoom in and out  with your scroll wheel or multitouch gestures (on supported platforms). Hold "Shift" to for Y-axis zooming.

Click and drag the X axis to pan in time.

### Screenshot

![Screenshot of PP2 on Windows 7](http://itdaniher.com/static/pp2_win7.png "Pixelpulse on Windows 7")

### Getting Pixelpulse2

To build from source on Linux / OSX with an appropriate C++ compiler and libraries:

* Install [LibUSB](http://libusb.info/) using the [appropriate branch](https://github.com/kevinmehall/libusb/tree/hp) if hotplug support on Windows is required or if building for Debian Wheezy based Linux distributions.
* Install Qt5.4 by downloading the proper release for your platform from [the Qt project](http://qtmirror.ics.com/pub/qtproject/development_releases/qt/5.4/5.4.0-rc/).

Run the following commands from a console environment:

    git clone --recursive https://github.com/signalspec/pixelpulse2
    cd pixelpulse2
    mkdir build
    cd build
    qmake ..
    make
    ./pixelpulse2

To get an up-to-date binary build for Windows:

 * Download the dependency package from [third-party hosting](https://kevinmehall.net/tmp/pixelpulse2_r3.zip)
 * Navigate to the [AppVeyor](https://ci.appveyor.com/project/kevinmehall/pixelpulse2/build/artifacts) page, download the 'release' .exe.
 * Extract the dependency package and overwrite the included pixelpulse2.exe with the latest build downloaded from AppVeyor.
 * With a M1K attached, double-click the executable to launch Pixelpulse.

To build / install for Debian, from the `pixelpulse2` directory:

    dh_make -p pixelpulse2_0.1 -s -c apache -e <email> --createorig
    dpkg-buildpackage


