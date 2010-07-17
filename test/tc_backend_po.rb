# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#

class TestBackendPO < Test::Unit::TestCase

  def setup
    I18n.load_path = Dir[ "#{$src_dir}/*.po" ]
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
