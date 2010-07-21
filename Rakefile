# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
$KCODE='UTF8'

require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/clean'

CLEAN << "coverage" << "pkg" << "README.html" << "CHANGELOG.html"

task :default => [:test, :doc, :gem]
Rake::TestTask.new(:test) do |t|
  t.pattern = File.join(File.dirname(__FILE__), 'test/all.rb')
  t.verbose = true
end

Rake::GemPackageTask.new(eval(File.read("i18n-translators-tools.gemspec"))) {|pkg|}

desc "Test with rcov"
task :rcov do |t| 
  system "rcov  --exclude .rvm --sort coverage --text-summary -o coverage  test/all.rb"
end

begin
  require 'bluecloth'

  def build_document(mdfile)
    fname = $1 if mdfile =~ /(.*)\.md$/
    raise "Unknown file type" unless fname

    data = File.read(mdfile)
    md = Markdown.new(data)
    htmlfile = "#{fname}.html"

    File.open(htmlfile, "w") { |f| f << md.to_html }
  end

  task :doc => [:readme, :changelog]

  task :readme do |t|
    build_document("README.md")
  end

  task :changelog do |t|
    build_document("CHANGELOG.md")
  end

rescue
end
