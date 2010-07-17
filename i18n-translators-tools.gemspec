# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

require 'rubygems'
require 'find'

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "I18n transation utility which helps to manage files with locales."
  s.email = "pejuko@gmail.com"
  s.authors = ["Petr Kovar"]
  s.name = 'i18n-translators-tools'
  s.version = '0.1'
  s.date = '2010-07-16'
  s.add_dependency('i18n', '>= 0.4.1')
  s.add_dependency('ya2yaml')
  s.require_path = 'lib'
  s.files = ["bin/i18n-translate", "test/tc_translate.rb", "test/locale/src/default.yml", "test/locale/src/cze.yml", "test/locale/src/cze.rb", "test/locale/src/cze.po", "lib/i18n-translate.rb", "lib/i18n/translate.rb", "lib/i18n/processor.rb", "lib/i18n/processor/yaml.rb", "lib/i18n/processor/ruby.rb", "lib/i18n/processor/gettext.rb", "lib/i18n/backend/translate.rb", "README.md", "i18n-translators-tools.gemspec", "Rakefile"]
  s.executables = ["i18n-translate"]
  s.description = <<EOF
This package brings you useful utility which can help you to handle locale files
and translations in your Ruby projects. Offers also built-in simple console editor.
Read README.md file and run i18n-translate without parameters for more information.
EOF
end

