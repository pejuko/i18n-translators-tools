# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#
require 'test/unit'
require 'rubygems'
require 'yaml'

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), ".."))
require 'lib/i18n-translate'

$current_dir = File.expand_path(File.dirname(__FILE__))
$src_dir = File.join($current_dir, 'locale/src')
$trg_dir = File.join($current_dir, 'locale/trg')

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


I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
I18n::Backend::Simple.send(:include, I18n::Backend::Translate)
I18n::Backend::Simple.send(:include, I18n::Backend::PO)
I18n.default_locale = 'default'
I18n.locale = 'cze'


Dir[File.join($current_dir, "tc_*.rb")].each do |tc|
  load tc
end
