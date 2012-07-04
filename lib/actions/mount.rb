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
### Attach an image to the device tree. Creates a device node for an
### existing image, allowing the image to be accessed using the standard
### file and disk manipulation commands.
###

# File handling classes
require "fs/geom"

class Bake < Thor
  
  desc "mount [IMAGE NAME]", "Make an image accessible through the /mnt directories"

  def mount(image_name = "pi.img")
    say("Attaching image #{image_name}", :blue)
    
    device_name = Geom.attach_image(image_name)
    
    unless device_name.nil? then
      say("...Image attached to #{device_name}", :blue)
    else
      say("ERROR: Could not attach #{image_name}", :red)
    end
    
    say("Mounting image #{image_name}...", :blue)
    
    if Geom.mount_image(device_name) then
      say("...Image mounted under /mnt", :blue)
    else
      say("ERROR: Could not mount #{image_name}", :blue)
      
      # try to unmount and detach the failed image
      unless Geom.umount_image_dirs then
        say("ERROR: Unable to unmount all the image directories", :red)
      end
      unless Geom.detach_image(device_name) then
        say("ERROR: Failed to detach device #{device_name}", :red)
      end
    end
  end

end
