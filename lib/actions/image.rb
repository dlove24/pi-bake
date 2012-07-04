### Copyright (c) 2012 David Love <david@homeunix.org.uk>
###
### Permission to use, copy, modify, and/or distribute this software for 
### any purpose with or without fee is hereby granted, provided that the 
### above copyright notice and this permission notice appear in all copies.
###
### THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES 
### WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF 
### MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR 
### ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES 
### WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN 
### ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF 
### OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
###

### @author David Love
###
### Image command. Creates the core disk image used as the master
### for the SD Card, booted by the Pi board.
###

# File handling classes
require "fs/geom"

class Bake < Thor

  desc "image [IMAGE NAME] [IMAGE SIZE]", "Prepare the SD Card image"

  def image(image_name = "pi", image_size = 4)
    # Create the full image name
    full_image_name = image_name + ".img"
    say("Creating the image file #{full_image_name}", :blue)

    # Work out the image size in bytes
    image_size_bytes = image_size * 1024 * 1024 * 1024

    ## Check for the existence of the named image in the current
    ## directory. If the image doesn't exist (or the user confirms
    ## an overwrite of the existing image), the image file is created
    
    if File.exists?(full_image_name) then
      if file_collision(full_image_name) then
        Geom.make_image(full_image_name, image_size_bytes)
      else
        say("Cannot create the requested image", :red)
        exit(1)
      end
    else
      Geom.make_image(full_image_name, image_size_bytes)
    end

    ##
    ## Now we need to partition the image, to create the basic disk
    ## structures
    ##
    
    say("Creating a device node for the image file...", :blue)
    
    # Attach the image to the kernel device tree
    device_name = Geom.attach_image(full_image_name)
    if device_name.nil?  then
      say("Cannot create the device node needed to access the requested image", :red)
      exit(1)
    end
    
    say("... Image file attached to #{device_name}", :blue)

    # Partition the disk image, creating the boot partition
    # and two system partition and a data partition. The basic
    # disk structures should like like the following
    #
    # partition 1: FAT32, 10% of the total disk  
    # partition 2: EXT2,  25% of the total disk  
    # partition 3: EXT2,  25% of the total disk  
    # partition 4: EXT2,  40% of the total disk
    #
    say("Partitioning the image file", :blue)
    
    Geom.prepare_image(device_name, image_size_bytes)

    # Finally detach the image
    say("Detaching the image file attached to #{device_name}", :blue)

    Geom.detach_image(device_name)
  end

end
