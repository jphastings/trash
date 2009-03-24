=begin rdoc
= Trash

This File class addon allows you to trash a file in your operating system of choice. In Mac OS X its as simple as putting the file in that's volume's .Trash directory, on Windows the Recycle Bin needs to be altered as the files are being trashed.

== Use

Usage is simple:
  File.trash("path/to/file")

The path is parsed by File.expand_path(), so relative directories are dealt with.

==== Supported Operating Systems
* Mac OS X - All Darwin based OSes
* Windows (Experimental, please test)

== Source

The source is available on github, 

== Contact

I have limited resources (especially when it comes to Operating Systems knowledge), if you'd like to help me develop this for other OSes please get in touch!
=end
require "rubygems"
require "ftools"
require "sys/uname"

class File
  # Moves the file whose filename is given to the Trash, Recycle Bin or equivalent of the OS being used.
  #
  # Will return a NotImplementtedError if your OS is not implemented.
  def self.trash(filename)
    filename = self.expand_path(filename)
    
    # Different Operating systems
    case Sys::Uname.sysname
    when "Darwin"
      if filename =~ /^\/Volumes\/(.+?)\//
        # External Volume, send to /Volumes/-volume name-/.Trashes/501/
        self.move(filename,"/Volumes/#{$1}/.Trashes/501/")
      else
        # Main drive, move to ~/.Trash/
        self.move(filename,self.expand_path("~/.Trash/"))
      end
    else
      raise NotImplementedError, "Sorry, Trash is not yet supported on your operating system"
    end
  end
end