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
require "fileutils"
require "fs/geom"

class Bake < Thor
  
  desc "update", "Update the boot directory with the latest firmware and kernel"

  def update(image_name = "pi.img")
    ##
    ## Prepare for the update
    ##
    
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
      
      exit
    end
    
    ##
    ## Fetch the latest version of the firmware
    ##
    
    abort = false
    
    # Fetch/update the upstream firmware
    if not File.exists?("firmware") then
      # Create the firmware directory, and clone the distributions
      # if this hasn't been done before
      say("Fetching upstream firmware...", :blue)
      
      unless system("git clone https://github.com/raspberrypi/firmware.git firmware") then
        say("ERROR: Failed to update firmware. Aborting.", :red)
        abort = true
      end
    else
      # Use git to get the latest version of the firmware
      say("Updating upstream firmware...", :blue)
            
      unless system("cd firmware; git pull") then
        say("ERROR: Failed to update firmware. Aborting.", :red)
        abort = false
      end
    end
    
    # Copy the system binaries to the boot directory
    unless abort then
      say("Updating firmware and kernel...", :blue)
      
      # Call the system directly, so that we can use sudo (i.e. don't use the native
      # ruby calls)
      unless system("sudo cp firmware/boot/bootcode.bin /mnt/pi-boot/bootcode.bin") then
        abort = true;
      end
      
      unless system("sudo cp firmware/boot/loader.bin /mnt/pi-boot/loader.bin") then
        abort = true;
      end
      
      unless system("sudo cp firmware/boot/arm224_start.elf /mnt/pi-boot/start.elf") then
        abort = true;
      end
      
      unless system("sudo cp firmware/boot/kernel.img /mnt/pi-boot/kernel.img") then
        abort = true;
      end
      
      say("...Done", :blue)
    end
    
    #cmdline.txt: Parameters passed to the kernel on boot

    ##
    ## Bootstrap the Debian (Raspbian) environment
    ##
    
    say("Bootstrapping the Debian (Raspbian) environment", :blue)
   
    # Download the modified bootstrap scripts
    #unless system("wget debian.tgz") then
    #  say("ERROR: Cannot find the bootstrap scripts", :red)
    #  abort = true
    #end 

    # Now try to do the actual bootstrap
    unless abort then
      unless system("sudo ./lib/deb/debootstrap --foreign --arch armhf wheezy /mnt/pi-system1 http://archive.raspbian.org/raspbian") then
        say("ERROR: Cannot find the bootstrap the Raspbian root", :red)
        abort = true
      end
    end 

    ##
    ## Cleanup
    ##
        
    # try to unmount and detach the image
    if Geom.umount_image_dirs then
      say("Unmounted staging directories", :blue)
    else
      say("ERROR: Unable to unmount all the image directories", :red)
    end
    
    if Geom.detach_image(device_name) then
      say("Detached image", :blue)
    else
      say("ERROR: Failed to detach device #{device_name}", :red)
    end
    
  end

end
