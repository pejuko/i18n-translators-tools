# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/clean'

CLEAN << "coverage" << "pkg"

task :default => [:test]
Rake::TestTask.new(:test) do |t|
  t.pattern = File.join(File.dirname(__FILE__), 'test/tc_*.rb')
  t.verbose = true
end

Rake::GemPackageTask.new(eval(File.read("i18n-translators-tools.gemspec"))) {|pkg|}
