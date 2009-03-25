spec = Gem::Specification.new do |s| 
  s.name = "Trash"
  s.version = "0.2"
  s.author = "JP Hastings-Spital"
  s.email = "trash@projects.kedakai.co.uk"
  s.homepage = "http://projects.kedakai.co.uk/trash"
  s.platform = Gem::Platform::RUBY
  s.summary = "Implements File.trash to move a file to the Recycle Bin, Trash or OS equivalent"
  s.files = ["trash.rb"]
  s.add_dependancy("fileutils")
  s.add_dependancy("sys-uname")
  s.add_dependancy("sys/admin")
  s.add_dependancy("sys/filesystem")
  s.add_dependancy("time")
  s.add_dependancy("iconv")
  s.require_path = "."
  s.has_rdoc = true
end