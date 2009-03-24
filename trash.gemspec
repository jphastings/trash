spec = Gem::Specification.new do |s| 
  s.name = "Trash"
  s.version = "0.1"
  s.author = "JP Hastings-Spital"
  s.email = "trash@projects.kedakai.co.uk"
  s.homepage = "http://projects.kedakai.co.uk/trash"
  s.platform = Gem::Platform::RUBY
  s.summary = "Implements File.trash to move a file to the Recycle Bin, Trash or OS equivalent"
  s.files = ["trash.rb"]
  s.add_dependency("ftools")
  s.add_dependancy("sys-uname")
  s.require_path = "."
  s.has_rdoc = true
end