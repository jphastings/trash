require "rubygems"
require "fileutils"
require "sys/uname"
require "sys/admin"
require "sys/filesystem"
require "time"
require "iconv"

# A class representing the database file used to store information about
# items stored in a windows recycle bin. 
#
# Details as to the structure can be found here: http://www.cybersecurityinstitute.biz/INFO2.htm
class WindowsRecycleDB
  
  # Open the INFO file and test it to make sure its valid  
  def initialize(filename)
    @fh = open(filename,"r+b")
    ## Check this is a valid INFO2 file
    # Read the first 16 bytes
    if @fh.readpartial(20).unpack("VVVvvV") != [5,0,0,800,0,0] # NB. the fourth element is the size of each record
      # Perhaps there is a better error to raise
      raise RuntimeError.new, "The file is not in the expected format"
    end
  end
  
  # Lists all the files stored in this INFO's recycle bin
  def records
    # Get to the end of the header
    @fh.seek(20)
    records = []
    while not @fh.eof?
      record = @fh.readpartial(800).unpack("Z260VVQVa520")
      break if @fh.eof?
      records.push({
        :record_number  => record[1],
        :filename_ascii => record[0],
        :filename       => Iconv.new("UTF-8","UTF-16LE").iconv(record[5]).strip,
        :size           => record[4],
        :drive_letter   => (record[2]+65).chr,
        :delete_time    => Time.at((record[3]/(10**7))-11644473600),
      })
    end
    records
  end
  
  # Adds a new record to the INFO database, and returns where the file should be moved to to comply with
  # the newly added data.
  def add(filename)
    raise StandardError, "That filename is invalid, its too long" if filename.length > 255
    # Get the next record number
    p n = getNextRecordNumber
     
    filename = File.expand_path(filename)
    filename.gsub!(/^([a-z])/){$1.upcase}
    
    utf8 = filename
    # Are there any UTF8 characters to deal with?
    if not filename =~ /^[\x21-\x7E]+$/i
      # Use File::SEPARATOR
      filename = filename[0,3]+(filename[3..-1].split("\\").collect { |chunk| ((chunk =~ /^[\x21-\x7E]+$/i) ? chunk : chunk.gsub(/([^a-z0-9_])/i,"")[0..5].upcase+"~1"+File.extname(chunk))}.join("\\"))
    end
    
    test = open("temp.txt","w")
    # Go to the end of the file, where the next record needs to be written
    @fh.sysseek(0, IO::SEEK_END)
    @fh.write filename.ljust(280,"\000")
    @fh.write [n].pack("V")
    @fh.write [filename.match(/^([A-Z]):/i)[1].upcase[0] - 65].pack("V")
    @fh.write [((Time.now.to_f+11644473600)*(10**7)).to_i].pack("Q")
    @fh.write [(open(utf8).read.length / Sys::Filesystem.stat(filename[0,3]).block_size).ceil].pack("V")
    @fh.write Iconv.new("UTF-16LE","UTF-8").iconv(utf8).ljust(520,"\000")
    @fh.write "\x0D\x0A"
    "D#{filename[0..0].downcase}#{n+1}"+File.extname(utf8)
  end
  
  private
  def getNextRecordNumber
    begin
      @fh.sysseek(-540, IO::SEEK_END)
      @fh.readpartial(4).unpack("V")[0] + 1
    rescue
      0
    end
  end
end

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
        FileUtils.mv(filename,"/Volumes/#{$1}/.Trashes/501/")
      else
        # Main drive, move to ~/.Trash/
        self.move(filename,self.expand_path("~/.Trash/"))
      end
    when /^Microsoft Windows/
      raise NotImplementedError, "There are some issues with Windows at the moment, sorry"
      break
      drive = filename.match(/^([A-Z]):/)[1]
      case Sys::Filesystem.stat("#{drive}:\\").base_type
      when "FAT32"
        bindir = drive+":\\Recycled\\"
      when "NTFS"
        bindir = drive+":\\RECYCLER\\"+Sys::Admin.get_user(Sys::Admin.get_login).sid+"\\"
      else
        raise NotImplememntedError, "I can't tell what filesystem this drive is using, I'm not going to presume where your Recycled/Recycler folder is"
        break
      end
      
      begin
        info = WindowsRecycleDB.new(self.expand_path(bindir+"INFO2"))
        moveto = info.add(filename)
        # For some reason this move line is failing, no idea why
        # If I copy the command and the strings its using to a new file it works...
        FileUtils.mv(filename.gsub("/","\\"),self.expand_path(bindir+moveto).gsub("/","\\"))
      rescue
        raise StandardError, "Couldn't update the Recycle Bin, no action taken"
      end
    else
      raise NotImplementedError, "Sorry, Trash is not yet supported on your operating system (#{Sys::Uname.sysname})"
    end
  end
end