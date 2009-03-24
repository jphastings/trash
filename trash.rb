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
      raise NotImplementedError, "Sorry, Trash is not yet supported on your operating system (#{Sys::Uname.sysname})"
    end
  end
end