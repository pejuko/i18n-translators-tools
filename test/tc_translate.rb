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
  [YAML.load(File.read(default))["default"], YAML.load(File.read(cze))["cze"]]
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
I18n.default_locale = 'default'
I18n.locale = 'cze'


class TestTranslatorPlugin < Test::Unit::TestCase

  def setup
    I18n.load_path << Dir[ "#{$src_dir}/*.yml" ]
    I18n.reload!
  end

  def test_0010_I18n_plugin_simple_text
    assert_equal( "Text k přeložení", I18n.t("simple.text") )
  end

  def test_0020_I18n_plugin_plural_text
    assert_equal( "Jedna položka", I18n.t("simple.plural", :count => 1) )
    assert_equal( "Mnoho položek", I18n.t("simple.plural", :count => 9))
  end

  def test_0030_I18n_plugin_interpolation
    assert_equal( "Interpolovaný text 'ahoj'", I18n.t("simple.interpolation", :var => "ahoj"))
  end

  def test_0040_I18n_plugin_translate_simple
    assert_equal( "Změněný jednoduchý text", I18n.t("changed.simple"))
  end

  def test_0050_I18n_plugin_translate_plural
    assert_equal( "Změněný plurál text", I18n.t("changed.plural", :count => 1))
    assert_equal( "Změněný plurál textů", I18n.t("changed.plural", :count => 9))
  end

  def test_0060_I18n_plugin_translate_interpolation
    assert_equal( "Interpolovaný změněný text 'ahoj'", I18n.t("changed.interpolation", :var => "ahoj"))
  end

end


class TestTranslate < Test::Unit::TestCase
  def setup
    @opts = {:locale_dir => $src_dir, :format => 'yml', :default_format => 'yml'}
    @t = I18n::Translate::Translate.new('cze', @opts)
    @t.options[:locale_dir] = $trg_dir
    I18n.load_path << Dir[ "#{$src_dir}/*.yml" ]
    I18n.reload!
  end

  def test_0010_initialize
    assert_not_equal(nil, @t)
    assert_equal( true, @t.kind_of?(I18n::Translate::Translate) )

    default, cze = load_src
    assert_equal( default, @t.default )
    assert_equal( cze, @t.target )
  end

  def test_0020_merge_simple
    assert_equal( { "key" => "simple.text",
                    "default" => "Text to translate",
                    "t" => "Text k přeložení",
                    "old_t" => "",
                    "old_default" => "",
                    "comment" => "",
                    "flag" => "ok" }, @t["simple.text"] )
  end

  def test_0030_merge_changed
    assert_equal( { "key" => "changed.simple",
                    "default" => "This text is newer and changed",
                    "t" => "",
                    "old_t" => "Změněný jednoduchý text",
                    "old_default" => "Changed simple text",
                    "comment" => "",
                    "flag" => "changed" }, @t["changed.simple"] )
  end

  def test_0040_assign_merge
    @t.assign(@t.merge)
    entry = @t.find("simple.text", @t.target )

    assert( entry.kind_of?(Hash) )
    assert_equal( { "t" => "Text k přeložení",
                    "old" => "",
                    "default" => "Text to translate",
                    "comment" => "",
                    "flag" => "ok"
                  }, entry )

    entry = @t.find("changed.simple", @t.target )
    assert_equal( { "t" => "Změněný jednoduchý text",
                    "old" => "Changed simple text",
                    "default" => "This text is newer and changed",
                    "comment" => "",
                    "flag" => "changed",
                    "fuzzy" => true
                  }, entry )
  end

  def test_0050_strip!
    @t.strip!
    entry = @t.find("changed.simple", @t.target )

    assert( entry.kind_of?(String) )
    assert_equal( "Změněný jednoduchý text", entry )
  end

  def test_0060_read_ruby
    trb = I18n::Translate::Translate.new('cze', @opts.merge({:format => 'rb'}))
    assert(trb.kind_of?(I18n::Translate::Translate))
    assert_equal(File.join(File.expand_path($src_dir), 'cze.rb'), trb.lang_file)
    assert_equal(@t.default, trb.default)
    assert_equal(@t.target, trb.target)
  end

  def test_0070_read_po
    tpo = I18n::Translate::Translate.new('cze', @opts.merge({:format => 'po'}))
    assert(tpo.kind_of?(I18n::Translate::Translate))
    assert_equal(File.join(File.expand_path($src_dir), 'cze.po'), tpo.lang_file)
    assert_equal(["changed.interpolation.default", "changed.interpolation.t", "changed.plural.one.default", "changed.plural.one.t", "changed.plural.other.default", "changed.plural.other.t", "changed.simple.default", "changed.simple.t", "simple.interpolation.default", "simple.interpolation.t", "simple.plural.one.default", "simple.plural.one.t", "simple.plural.other.default", "simple.plural.other.t", "simple.text.default", "simple.text.t"], I18n::Translate.hash_to_keys(tpo.target, ".").sort)
  end

end

