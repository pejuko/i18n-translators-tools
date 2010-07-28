# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

require 'rubygems'
require 'find'

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "I18n translation utility which helps to manage files with locales."
  s.homepage = "http://github.com/pejuko/i18n-translators-tools"
  s.email = "pejuko@gmail.com"
  s.authors = ["Petr Kovar"]
  s.name = 'i18n-translators-tools'
  s.version = '0.2.2'
  s.date = Time.now.strftime("%Y-%m-%d")
  s.add_dependency('i18n', '>= 0.4.1')
  s.add_dependency('ya2yaml')
  s.require_path = 'lib'
  s.files = ["bin/i18n-translate", "README.md", "i18n-translators-tools.gemspec", "Rakefile"]
  s.files += Dir["lib/**/*.rb", "test/**/*.{rb,yml,po}"]
  s.executables = ["i18n-translate"]
  s.post_install_message = <<EOF
=============================================================================

I18N TRANSLATORS TOOLS

-----------------------------------------------------------------------------

Supported formats:
  * yml
  * rb
  * ts
  * po
  * properties

Backends:
  * Extended format. i18n-translators-tools brings extended format
    I18n::Backend::Simple.send(:include, I18n::Backend::Translator)
  * Gettext po
    I18n::Backend::Simple.send(:include, I18n::Backend::PO)
  * QT Linguist TS
    I18n::Backend::Simple.send(:include, I18n::Backend::TS)
  * Java Properties files
    I18n::Backend::Simple.send(:include, I18n::Backend::Properties)

Functions:
  * merge
  * convert
  * translate (built-in simple console translator)
  * statistics

Changelog:
  v0.2.1
    * fix: I18n::Backend::Translate now returns nil if translation is empty
      string (this allows fallbacks)

  v0.2.2
    * fix: don't merge if default file doesn't exist (locale stays untouched)
    * fix: for default format autodetection works again
    * merge can be more verbose

For more information read README.md and CHANGELOG.md

-----------------------------------------------------------------------------

http://github.com/pejuko/i18n-translators-tools

=============================================================================
EOF
  s.description = <<EOF
This package brings you useful utility which can help you to handle locale files
and translations in your Ruby projects. Offers also built-in simple console editor.
Supported formats are YAML, Ruby, Gettext po, QT Linguist TS and Java Properties.
Read README.md file and run i18n-translate without parameters for more information.
EOF
end

