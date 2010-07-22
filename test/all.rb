# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#
$KCODE='UTF8'

require 'test/unit'
require 'rubygems'
require 'yaml'

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), ".."))
require 'lib/i18n-translate'
require 'test/backend'
require 'test/processor'

$current_dir = File.expand_path(File.dirname(__FILE__))
$src_dir = File.join($current_dir, 'locale/src')
$trg_dir = File.join($current_dir, 'locale/trg')


    # some data for comparation
$si = {
  "comment" => "Comment",
  "extracted_comment" => "Extracted Comment",
  "reference" => "src/test.rb:31",
  "file" => "src/test.rb",
  "line" => "31",
  "fuzzy" => true,
  "flag" => "incomplete",
  "old_default" => "Previous untranslated",
  "default" => "Interpolated text '%{var}'",
  "translation" => "Interpolovaný text '%{var}'"
}


def load_yml(default, cze)
  tr = I18n::Translate::Translate.new('default', {:empty => true})
  [ I18n::Translate::Processor.read(default, tr)["default"],
    I18n::Translate::Processor.read(cze, tr)["cze"] ]
end

def load_src
  load_yml("#{$src_dir}/default.yml", "#{$src_dir}/cze.yml")
end

def load_trg
  load_yml("#{$trg_dir}/default.yml", "#{$trg_dir}/cze.yml")
end

def load_src_trg
  res = {}
  res[:src] = load_src
  res[:trg] = load_trg
  res
end


# helper for comparing Hasheds and Arrays
# prints out differences
def diff(src, trg)
  return if src == trg
  if src.kind_of?(Hash) and trg.kind_of?(Hash)
    src.keys.each { |key| puts "src key: #{key}" unless trg.keys.include?(key) }
    trg.keys.each { |key| puts "trg key: #{key}" unless src.keys.include?(key) }
    src.keys.each do |key, value|
      puts "#{key} #{src[key].inspect} != #{trg[key].inspect}" if src[key] != trg[key]
    end
  elsif src.kind_of?(Array) and trg.kind_of?(Array)
    src.each {|k| puts "not in trg '#{k}'" unless trg.include?(k)}
    trg.each {|k| puts "not in src '#{k}'" unless src.include?(k)}
  else
    puts "not equal types"
  end
end


I18n::Backend::Simple.send(:include, I18n::Backend::Translate)
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
I18n::Backend::Simple.send(:include, I18n::Backend::PO)
I18n::Backend::Simple.send(:include, I18n::Backend::TS)
I18n::Backend::Simple.send(:include, I18n::Backend::Properties)
I18n.default_locale = 'default'
I18n.locale = 'cze'


Dir[File.join($current_dir, "tc_*.rb")].each do |tc|
  load tc
end
