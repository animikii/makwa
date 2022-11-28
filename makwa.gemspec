# frozen_string_literal: true

require_relative "lib/makwa/version"

Gem::Specification.new do |spec|
  spec.name = "makwa"
  spec.version = Makwa::VERSION
  {
    "Jo Hund" => "jo@animikii.com",
    "Fabio Papa" => "fabio.papa@animikii.com"
  }.tap do |hash|
    spec.authors = hash.keys
    spec.email = hash.values
  end
  spec.summary = "Interactions for Ruby on Rails apps."
  spec.homepage = "https://github.com/animikii/makwa"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/animikii/makwa"
  spec.metadata["changelog_uri"] = "https://github.com/animikii/makwa/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "active_interaction", "~> 5.2.0"

  spec.add_development_dependency "standard"
  spec.add_development_dependency "byebug"
end
