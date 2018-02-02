## Pixelpulse2

[![Windows Status](https://ci.appveyor.com/api/projects/status/32r7s2skrgm9ubva?svg=true)](https://ci.appveyor.com/project/analogdevicesinc/pixelpulse2/branch/master)
[![OSX Status](https://api.travis-ci.org/analogdevicesinc/Pixelpulse2.svg?branch=master&label=OSX)](https://travis-ci.org/analogdevicesinc/Pixelpulse2)
[![License](https://img.shields.io/badge/license-MPL-blue.svg)](https://github.com/analogdevicesinc/Pixelpulse2/blob/master/LICENSE)

Pixelpulse is a powerful user interface for visualizing and manipulating signals while exploring systems attached to affordable analog interface devices, such as Analog Devices' ADALM1000.

Fully cross-platform using the Qt5 graphics toolkit and OpenGL accelerated density-gradiated rendering, it provides a powerful and accessible tool for initial interactive explorations.

Intuitive click-and-drag interfaces make exploring system behaviors across a wide range of signal amplitudes, frequencies, or phases a trivial exercise. Just click once to source a constant voltage or current and see what happens. Choose a function (sawtooth, triangle, sinusoidal, square) - adjust parameters, and make waves.

Zoom in and out  with your scroll wheel or multitouch gestures (on supported platforms). Hold "Shift" to for Y-axis zooming.

Click and drag the X axis to pan in time.

### Screenshot

![Screenshot of PP2 on Windows 7](https://analogdevicesinc.github.io/Pixelpulse2/pp2screenshot.png "Pixelpulse on Windows 7")

### Getting Pixelpulse2

#### Easy

* OSX - Navigate to the [releases](https://github.com/analogdevicesinc/pixelpulse2/releases) and collect the latest `pixelpulse2-bundled.dmg.zip` package. The latest testing build is available from [Travis-CI](http://pixelpulse2nightly.s3-website-us-east-1.amazonaws.com/pixelpulse2.dmg).
* Windows - For a testing build, download the dependency package and the latest binary build from [appveyor](https://ci.appveyor.com/project/analogdevicesinc/pixelpulse2/build/artifacts). For an official release build, navigate to releases and collect the latest pixelpulse2-setup.exe.
* Linux - Either build from source (below) or navigate to the releases and collect the latest .deb or .tgz file for your architecture. Install or extract as appropriate.

#### Advanced

To build from source on any platform, you need to install a C++ compiler toolchain, collect the build dependencies, setup your build environment, and compile the project.

If you have not built packages from source before, this is ill-advised.
* Build and install libsmu (https://github.com/analogdevicesinc/libsmu)
* Install Qt5.4.
 * On most Linux Distributions, Qt5 is available in repositories. The complete list of packages required varies, but includes qt's support for declarative (qml) UI programming, qtquick, qtquick-window, qtquick-controls, and qtquick-layouts.
 * Binary installers are available from [the Qt project](http://qtmirror.ics.com/pub/qtproject/development_releases/qt/5.4/5.4.0-rc/) for most platforms.

To build / run on a generic POSIX platform

    git clone https://github.com/signalspec/pixelpulse2
    cd pixelpulse2
    mkdir build
    cd build
    qmake pixelpulse2.pro -qt=qt5
    make

On Windows the qmake command should look like this

    qmake pixelpulse2.pro "LIBSMU_LIBRARY = path_to_libsmu_dll" "LIBSMU_INCLUDE_PATH = path_to_libsmu_include_folder" -qt=qt5

After it is finished building, you have to copy the libsmu shared library into the build folder and Pixelpulse2 should be ready to use with your M1K

To build / install for Debian, from the `pixelpulse2` directory:

    dh_make -p pixelpulse2_0.8 -s -c blank --createorig
    dpkg-buildpackage
    sudo dpkg -i ../pixelpulse2_0.1-1_i386.deb

To build / run on Ubuntu 15.04, via [shabaz on Farnell](http://www.element14.com/community/groups/test-and-measurement/blog/2015/02/14/getting-started-with-the-active-learning-module-adalm1000).  

 * Please note that you make encounter issues if you are running a version of Ubuntu lower than 15.04, because the version of QT in the repositories will likely be less than 5.4 (this also applies if you are running a Linux distribution that uses an older version of Ubuntu, for example Linux Mint 17.1, which uses Ubuntu 14.04.)

* Get ready

    ```bash
    sudo apt-get update
    ```

* Build and install libsmu (https://github.com/analogdevicesinc/libsmu)

* Download and install Qt5.4

    ```bash
    wget http://qtmirror.ics.com/pub/qtproject/development_releases/qt/5.4/5.4.0-rc/qt-opensource-linux-x64-5.4.0-rc.run
    chmod 755 qt-o*
    ./qt-opensource-linux-x64-5.4.0-rc.run
    ```
    
* Install a couple extra Qt modules
    ```bash
    sudo apt-get install qtdeclarative5-controls-plugin
    sudo apt-get install qtdeclarative5-quicklayouts-plugin
    sudo apt-get install qtdeclarative5-dev
    ```

* Change your default configuration file

    ```bash
    sudo su
    cd /usr/lib/x86_64-linux-gnu/qt-default/qtchooser
    ls -l
    rm default.conf
    ln -s ../../../../share/qtchooser/qt5-x86_64-linux-gnu.conf default.conf
    ls –l
    exit
    ```

* Make a new folder, clone the pixelpulse library into it from git, and build it!

    ```bash
    mkdir development
    cd development
    git clone https://github.com/signalspec/pixelpulse2
    cd pixelpulse2
    mkdir build
    cd build
    qmake pixelpulse2.pro ..
    make
    ```

* After it is finished building,you have to copy the libsmu shared library into the build folder and Pixelpulse2 should be ready to use with your M1K
 * Make sure your M1K is plugged into your computer.  The onboard LED should light up when it is connected.  You can double-check by typing ```lsusb```.  You should see something along the lines of ```ID 064b:784c Analog Devices, Inc. (White Mountain DSP)```
 * You should be ready to launch Pixelpulse2. First, go to the directory it was built in:
    
    ```bash
    cd ~/development/pixelpulse2/build
    ```

 * Run Pixelpulse2 as root

    ```bash
    sudo ./pixelpulse2
    ```

