# FreeBSD Raspbery Pi Image Builder #

This builder creates disk images, which can then be used prepare SD cards for the Raspbery PI. Instead of transferring a pre-prepared image file to the SD card, this build tool focus only the on the process of creating, formatting and preparing a disk image. The images created using this tool can then be treated like any other disk image, and transferred to the Pi in the [usual way](http://elinux.org/RPi_Easy_SD_Card_Setup),

The aim of this tool is to quickly prepare customised card images, to allow the Pi boards to be used in different teaching sessions within the Networking Labs, at the Department of Computing at Sheffield Hallam University. We treat the SD Cards as somewhat disposable, swapping cards to change the functionality of the Pi boards. This requires access to a library of suitable images: which this tool aims to help create.

**Note:** This means this build is *not* suitable as a general-use/media machine. We assume the data on the SD card is either disposable, or located on the network somewhere. You might be able to build and image which is suitable as a general use machine, but you might want to try [something else](http://www.raspberrypi.org/downloads).

# Where Next? #

Unless you are interested in contributing to the tool, you probably want to be somewhere else. For more details of how to install, and use, this tool please see the [Wiki](http://github.com/dlove24/pi-bake/wiki). If you are interested in contributing, you can also find details of the inner workings [here](http://dlove24.github.com). Ideas, changes, and patches are always welcome.

# Contributing to pi-bake #
 
* Check out the latest master to make sure the feature hasn't been
  implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't
  requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it
  in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you
  want to have your own version, or is otherwise necessary, that is
fine, but please isolate to its own commit so I can cherry-pick around
it.

# Copyright #

Copyright (c) 2012 David Love. See LICENSE.txt for
further details.
