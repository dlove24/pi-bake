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
### FreeBSD GEOM Interface. Packages the FreeBSD GEOM interfaces and utilities into
### a single class.
###

# Sub-process handling library
require "open4"

class Geom

  # Attach a disk image
  def self.attach_image(image_name)

    # Sanity check the FreeBSD environment, making sure the
    # geom_gate kernel module is loaded (or can be loaded) before
    # we do anything else

    unless system("kldstat -q -m ggate") then
      
      # The kernel module isn't loaded, so lets try to
      # load it
      unless system("sudo kldload geom_gate") then
        # OK now we are really stuck. The correct module 
        # isn't available, and we can't load it either.
        # Not much else we can do now.
        return nil
      end

      # Did that work?
      unless system("kldstat -q -m ggate") then
        # No, so tell the caller
        return nil
      end
    end 

    # Attach the image
    #
    # NOTE: There appears to be a bug in the output of ggatel, which
    # fails to report the newly created device name. Instead we have
    # to reconstruct the new name, and report it to the caller.
    
    current_devices = `ggatel list`.split
    `sudo ggatel create #{image_name}`
    updated_devices = `ggatel list`.split

    device_name = updated_devices - current_devices

    return device_name[0].to_s
  end
  
  # Detach a disk image
  def self.detach_image(device_name)
    device_number = device_name[-1]
    system("sudo ggatel destroy -u #{device_number}")
  end
  
  # Create a blank disk image, backed by the named file
  def self.make_image(image_name, image_size)
    # Work out how many 512 bit blocks we need
    blocks = image_size / 512
 
    # Create a spare image of the required size
    puts "Image size: #{image_size} bytes"
    `dd of=#{image_name} bs=512 count=0 seek=#{blocks}`
  end
  
  # Mount the image slices in known locations
  def self.mount_image(device_name)
    
    # Sanity check the FreeBSD environment, making sure the
    # ext2fs kernel module is loaded (or can be loaded) before
    # we do anything else

    unless system("kldstat -q -m ext2fs") then
      
      # The kernel module isn't loaded, so lets try to
      # load it
      unless system("sudo kldload ext2fs") then
        # OK now we are really stuck. The correct module 
        # isn't available, and we can't load it either.
        # Not much else we can do now.
        return false
      end

      # Did that work?
      unless system("kldstat -q -m ext2fs") then
        # No, so tell the caller
        return false
      end
    end
    
    # Mount the boot slice
    unless File.exists?("/mnt/pi-boot") then
      # Use sudo to assume root powers, instead of the
      # native ruby method
      `sudo mkdir -p /mnt/pi-boot`
    end
    
    unless system("sudo mount_msdosfs /dev/#{device_name}s1 /mnt/pi-boot") then
      return false
    end

    # Mount the boot slice
    unless File.exists?("/mnt/pi-system1") then
    # Use sudo to assume root powers, instead of the
    # native ruby method
    `sudo mkdir -p /mnt/pi-system1`
    end

    unless system("sudo mount -t ext2fs /dev/#{device_name}s2 /mnt/pi-system1")
      return false
    end

    # Mount the boot slice
    unless File.exists?("/mnt/pi-system2") then
    # Use sudo to assume root powers, instead of the
    # native ruby method
    `sudo mkdir -p /mnt/pi-system2`
    end

    unless system("sudo mount -t ext2fs /dev/#{device_name}s3 /mnt/pi-system2")
      return false
    end

    # Mount the boot slice
    unless File.exists?("/mnt/pi-data") then
     # Use sudo to assume root powers, instead of the
     # native ruby method
     `sudo mkdir -p /mnt/pi-data`
    end

    unless system("sudo mount -t ext2fs /dev/#{device_name}s4 /mnt/pi-data")
      return false
    end
    
    return true
    
  end

  # Set-up the basic disk partition table, and file systems
  def self.prepare_image(device_name, image_size)
    
    ##
    ## Partition the disk image
    ##

    # Calculate the size of a block that is 1% of the total
    # disk space
    block_size = image_size.to_f / 100.0
    
    # Calculate the number of cylinders based on 512 sector
    # size, 255 heads and 63 sectors per track
    cylinders = (image_size.to_f / 255.0 / 63.0 / 512.0).floor

    # Tell the user what we have done
    puts "Heads:         255"
    puts "Sectors/Track: 63"
    puts "Cylinder:      #{cylinders}" 
    puts
    puts "Block size:    #{(block_size / 1024.0 / 1024.0).floor}MB"
    puts 
    puts "Layout"
    puts "------------------------------------------"
    puts "P1: #{((block_size * 10) / 1024.0 / 1024.0).floor}MB"
    puts "P2: #{((block_size * 25) / 1024.0 / 1024.0).floor}MB"
    puts "P3: #{((block_size * 25) / 1024.0 / 1024.0).floor}MB"
    puts "P4: #{((block_size * 40) / 1024.0 / 1024.0).floor}MB"
    puts 
     
    config_file = String.new 
    config_file << "g s63 h255 c" + cylinders.floor.to_s + "\n"
    config_file << "p \t 1 \t 0x0C \t 63 \t #{((block_size * 10) / 1024.0 / 1024.0).floor}M\n" 
    config_file << "p \t 2 \t 0x83 \t *  \t #{((block_size * 25) / 1024.0 / 1024.0).floor}M\n" 
    config_file << "p \t 3 \t 0x83 \t *  \t #{((block_size * 25) / 1024.0 / 1024.0).floor}M\n" 
    config_file << "p \t 4 \t 0x83 \t *  \t *\n"
    config_file << "a 1\n"

    cmd = "sudo fdisk -f - -i " + device_name
    status = open4.spawn(cmd, :stdin => config_file)

    ##
    ## Format the partitions
    ##

    # Create a FAT-32 file system in the boot partition
    puts "Formatting #{device_name}s1 as FAT-32..."
    `sudo newfs_msdos -F 32 -L PI-BOOT /dev/#{device_name}s1`

    # Everything else is EXT2
    puts "Formatting #{device_name}s2 as ext2..."
    `sudo mkfs.ext2 -I 128 /dev/#{device_name}s2`
    puts "Formatting #{device_name}s3 as ext2..."
    `sudo mkfs.ext2 -I 128 /dev/#{device_name}s3`
    puts "Formatting #{device_name}s4 as ext2..."
    `sudo mkfs.ext2 -I 128 /dev/#{device_name}s4`

  end
  
  def self.umount_image_dirs
    unless system("sudo umount /mnt/pi-boot") then
      return false
    end
    unless system("sudo umount /mnt/pi-system1") then
      return false
    end
    unless system("sudo umount /mnt/pi-system2") then
      return false
    end
    unless system("sudo umount /mnt/pi-data") then
      return false
    end
    
    return true
  end

end
