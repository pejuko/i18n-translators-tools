# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#

class TestTranslate < Test::Unit::TestCase
  def setup
    @opts = {:locale_dir => $src_dir, :format => 'yml', :default_format => 'yml'}
    @t = I18n::Translate::Translate.new('cze', @opts)
    @t.options[:locale_dir] = $trg_dir
    I18n.load_path = Dir[ "#{$src_dir}/*.yml" ]
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
                    "translation" => "Text k přeložení",
                    "old_translation" => "",
                    "old_default" => "",
                    "comment" => "",
                    "flag" => "ok" }, @t["simple.text"] )
  end

  def test_0030_merge_changed
    assert_equal( { "key" => "changed.simple",
                    "default" => "This text is newer and changed",
                    "translation" => "",
                    "old_translation" => "Změněný jednoduchý text",
                    "old_default" => "Changed simple text",
                    "comment" => "",
                    "flag" => "changed" }, @t["changed.simple"] )
  end

  def test_0040_assign_merge
    @t.assign(@t.merge)
    entry = @t.find("simple.text", @t.target )

    assert( entry.kind_of?(Hash) )
    assert_equal( { "translation" => "Text k přeložení",
                    "default" => "Text to translate",
                    "flag" => "ok"
                  }, entry )

    entry = @t.find("changed.simple", @t.target )
    assert_equal( { "translation" => "Změněný jednoduchý text",
                    "old_default" => "Changed simple text",
                    "default" => "This text is newer and changed",
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
    diff(@t.target, trb.target)
    assert_equal(@t.target, trb.target)
  end

  def test_0070_read_po
    tpo = I18n::Translate::Translate.new('cze', @opts.merge({:format => 'po'}))
    assert(tpo.kind_of?(I18n::Translate::Translate))
    assert_equal(File.join(File.expand_path($src_dir), 'cze.po'), tpo.lang_file)
    assert_equal(@t.target.keys.sort, tpo.target.keys.sort)
    assert_equal($si, tpo.target["extended"]["interpolation"])
  end

  def test_0080_convert
    t = I18n::Translate::Translate.new('cze', @opts.merge({:format => 'yml'}))
    t.options[:locale_dir] = $trg_dir
    t.options[:format] = 'po'
    t.export!
    trg_file = File.join($trg_dir, "cze.po")
    assert( File.exists?(trg_file) )
    t2 = I18n::Translate::Translate.new('cze', @opts.merge({:format => 'po'}))
    assert_equal( t.target["extended"]["interpolation"], t2.target["extended"]["interpolation"] )
    File.unlink(trg_file)
  end

end



class TestTranslateTools < Test::Unit::TestCase

  def setup
    @hash = {}
  end

  def test_0010_scan_list_files
    locales = I18n::Translate.scan(:locale_dir => $src_dir).map{ |x| x =~ /\/([^\/]+)$/; $1 }.sort
    assert_equal( %w(cze.po cze.properties cze.rb cze.ts cze.yml po_to_ts.ts).sort, locales )
  end

  def test_0011_scan_list_files_format
    locales = I18n::Translate.scan(:locale_dir => $src_dir, :format => 'yml').map{ |x| x =~ /\/([^\/]+)$/; $1 }.sort
    assert_equal( %w(cze.yml).sort, locales )
  end

  def test_0012_scan_list_files_exclude
    locales = I18n::Translate.scan(:locale_dir => $src_dir, :exclude => ['yml']).map{ |x| x =~ /\/([^\/]+)$/; $1 }.sort
    assert_equal( %w(cze.po cze.properties cze.rb cze.ts po_to_ts.ts).sort, locales )
  end

  def test_0013_scan_list_deep
    locales = I18n::Translate.scan(:locale_dir => $src_dir, :deep => true).map{ |x| x =~ /\/([^\/]+)$/; $1 }.sort
    assert_equal( %w(cze.po cze.properties cze.rb cze.ts cze.yml cze.yml eng.yml po_to_ts.ts).sort, locales )
  end

  def test_0013_scan_list_deep_exclude
    locales = I18n::Translate.scan(:locale_dir => $src_dir, :deep => true, :exclude => ['cze']).map{ |x| x =~ /\/([^\/]+)$/; $1 }.sort
    assert_equal( %w(eng.yml po_to_ts.ts).sort, locales )
  end

  def test_0020_scan_block
    I18n::Translate.scan(:locale_dir => $src_dir, :default_format => 'yml') do |tr|
      entry = tr.find("simple.text")
      str = "Text k přeložení"
      if entry.kind_of?(String)
        assert_equal( str, entry )
      else
        assert_equal( str, entry["translation"] )
      end
    end
  end

  def test_0030_set_bad_separator
    I18n::Translate.set("a.b.c", "Value", @hash, "|")
    assert_equal( {"a.b.c" => "Value"}, @hash )
  end

  def test_0040_set
    I18n::Translate.set("a.b.c", "Value", @hash)
    assert_equal( {"a" => {"b" => {"c" => "Value"}}}, @hash )

    I18n::Translate.set("a.b.d", "Value 2", @hash)
    assert_equal( {"a" => {"b" => {"c" => "Value", "d" => "Value 2"}}}, @hash )
  end

  def test_0050_find_in_empty_hash
    entry = I18n::Translate.find("a.b.c", @hash)
    assert_equal( nil, entry )
  end

  def test_0050_find
    I18n::Translate.set("a.b.c", "Value", @hash)
    I18n::Translate.set("a.b.d", "Value 2", @hash)
    entry = I18n::Translate.find("a.b.c", @hash)
    assert_equal( "Value" , entry )
  end

  def test_0060_hash_to_keys_empty_hash
    keys = I18n::Translate.hash_to_keys(@hash)
    assert_equal( [], keys )
  end

  def test_0060_hash_to_keys_empty_hash
    I18n::Translate.set("a.b.c", "Value", @hash)
    I18n::Translate.set("a.b.d", "Value 2", @hash)
    keys = I18n::Translate.hash_to_keys(@hash)
    assert_equal( %w(a.b.c a.b.d), keys )
  end

end

