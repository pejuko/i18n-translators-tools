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
                    "old_default" => "",
                    "default" => "Text to translate",
                    "comment" => "",
                    "flag" => "ok"
                  }, entry )

    entry = @t.find("changed.simple", @t.target )
    assert_equal( { "translation" => "Změněný jednoduchý text",
                    "old_default" => "Changed simple text",
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
    assert_equal(["changed.interpolation.default",
                  "changed.interpolation.translation",
                  "changed.plural.one.default",
                  "changed.plural.one.translation",
                  "changed.plural.other.default",
                  "changed.plural.other.translation",
                  "changed.simple.default",
                  "changed.simple.translation",
                  "simple.interpolation.comment",
                  "simple.interpolation.default",
                  "simple.interpolation.extracted_comment",
                  "simple.interpolation.file",
                  "simple.interpolation.flag",
                  "simple.interpolation.line",
                  "simple.interpolation.old_default",
                  "simple.interpolation.reference",
                  "simple.interpolation.translation",
                  "simple.plural.one.default",
                  "simple.plural.one.translation",
                  "simple.plural.other.default",
                  "simple.plural.other.translation",
                  "simple.text.default",
                  "simple.text.translation",
                  "test.new_line.default",
                  "test.new_line.translation",
                  "test.quote.default",
                  "test.quote.translation"
    ], I18n::Translate.hash_to_keys(tpo.target, ".").sort)
  end

end

