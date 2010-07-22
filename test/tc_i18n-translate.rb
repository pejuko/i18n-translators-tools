# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#

# this test is testing bin/i18n-translate utility
# all writing is done through pipe
# and results are checked from file
class TestI18nTranslateTool < Test::Unit::TestCase

  def setup
    @src_file = File.join($src_dir, "cze.yml")
    @trg_file = File.join($trg_dir, "cze.yml")
    @default_src = File.join($src_dir, "default.yml")
    @default_trg = File.join($trg_dir, "default.yml")
    @bin = File.expand_path( File.join($current_dir, "../bin/i18n-translate") )
    FileUtils.cp(@src_file, @trg_file)
    FileUtils.cp(@default_src, @default_trg)
    @tr = I18n::Translate::Translate.new('cze', :locale_dir => $trg_dir, :format => "yml")
    @io = IO.popen("#{@bin} translate -l cze --locale_dir=#{$trg_dir} -f yml", "r+")
  end

  def test_0010_translate_first_entry
    str = "Tento interpolovaný text je novější '%{var}'"
    @io.puts("t\n")
    @io.puts(str)
    @io.puts("q")
    @io.close
    t = I18n::Translate::Translate.new('cze', :locale_dir => $trg_dir, :format => "yml")
    assert_not_equal(t.target, @tr.target)
    assert_equal( str, t.target["changed"]["interpolation"]["translation"] )
  end

  def test_0010_translate_first_entry
    str = "Tento interpolovaný text je novější '%{var}'"
    @io.puts("t\n")
    @io.puts(str)
    @io.puts("q")
    @io.close
    t = I18n::Translate::Translate.new('cze', :locale_dir => $trg_dir, :format => "yml")
    assert_not_equal(t.target, @tr.target)
    assert_equal( str, t.target["changed"]["interpolation"]["translation"] )
    assert_equal( "ok", t.target["changed"]["interpolation"]["flag"] )

    File.unlink(@trg_file)
    File.unlink(@default_trg)
  end

  def test_0020_translate_first_entry_flag
    str = "Tento interpolovaný text je novější '%{var}'"
    @io.puts("t\n")
    @io.puts(str)
    @io.puts("f")
    @io.puts("i")
    @io.puts("q")
    @io.close
    t = I18n::Translate::Translate.new('cze', :locale_dir => $trg_dir, :format => "yml")
    assert_not_equal(t.target, @tr.target)
    assert_equal( str, t.target["changed"]["interpolation"]["translation"] )
    assert_equal( "incomplete", t.target["changed"]["interpolation"]["flag"] )

    File.unlink(@trg_file)
    File.unlink(@default_trg)
  end

  def test_0030_translate_first_entry_comment
    str = "Nějaký komentář"
    @io.puts("c\n")
    @io.puts(str)
    @io.puts("q")
    @io.close
    t = I18n::Translate::Translate.new('cze', :locale_dir => $trg_dir, :format => "yml")
    assert_not_equal(t.target, @tr.target)
    assert_equal( str, t.target["changed"]["interpolation"]["comment"] )
    assert_equal( "changed", t.target["changed"]["interpolation"]["flag"] )

    File.unlink(@trg_file)
    File.unlink(@default_trg)
  end

  def test_0030_translate_first_entry_save_and_then_exit
    str = "Nějaký komentář"
    @io.puts("c\n")
    @io.puts(str)
    @io.puts("s")
    @io.puts("x")
    @io.close
    t = I18n::Translate::Translate.new('cze', :locale_dir => $trg_dir, :format => "yml")
    assert_not_equal(t.target, @tr.target)
    assert_equal( str, t.target["changed"]["interpolation"]["comment"] )
    assert_equal( "changed", t.target["changed"]["interpolation"]["flag"] )

    File.unlink(@trg_file)
    File.unlink(@default_trg)
  end

  def test_0040_translate_quit_without_saving
    str = "Tento interpolovaný text je novější '%{var}'"
    @io.puts("t\n")
    @io.puts(str)
    @io.puts("x")
    @io.close
    t = I18n::Translate::Translate.new('cze', :locale_dir => $trg_dir, :format => "yml")
    assert_equal(t.target, @tr.target)
    assert_not_equal( str, t.target["changed"]["interpolation"]["translation"] )

    File.unlink(@trg_file)
    File.unlink(@default_trg)
  end

  def test_0050_next_and_translate
    str = "Tento text jen novější množné číslo"
    @io.puts("n")
    @io.puts("t\n")
    @io.puts(str)
    @io.puts("q")
    @io.close
    t = I18n::Translate::Translate.new('cze', :locale_dir => $trg_dir, :format => "yml")
    assert_not_equal(t.target, @tr.target)
    assert_equal( str, t.target["changed"]["plural"]["one"]["translation"] )
    assert_equal( "ok", t.target["changed"]["plural"]["one"]["flag"] )

    File.unlink(@trg_file)
    File.unlink(@default_trg)
  end

end
