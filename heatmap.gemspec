$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "heatmap/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "heatmap"
  s.version     = Heatmap::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Heatmap."
  s.description = "TODO: Description of Heatmap."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "kdtree"
end
