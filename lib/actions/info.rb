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
### Display image command. Shows information about the image file, obtained
### from the file system wherever possible. This command is principally
### used to debug problems during development.
###

# File handling classes
require "fs/geom"

class Bake < Thor

  desc "info [IMAGE NAME]", "Display information about the image file"

  def info(image_name = "pi")
    full_image_name = image_name + ".img"

    # Attach the image to the device tree so that we can have a
    # look at it

    say("Creating a device node for the image file #{full_image_name}...", :blue)
    
    # Attach the image to the kernel device tree
    device_name = Geom.attach_image(full_image_name)
    if device_name.nil?  then
      say("Cannot create the device node needed to access the requested image", :red)
      exit(1)
    end
    
    say("... Image file attached to #{device_name}", :blue)

    # Display the structures reported by FDisk

    puts
    puts "  Summary of the image partition layout"
    puts "--------------------------------------------------------------------"
    puts `sudo fdisk -s #{device_name}`
    puts

    # Finally detach the image
    say("Detaching the image file attached to #{device_name}", :blue)

    Geom.detach_image(device_name)
  end

end
