# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#

class TestBackendTranslate < Test::Unit::TestCase

  def setup
    I18n.load_path = Dir[ "#{$src_dir}/default.yml", "#{$src_dir}/cze.yml" ]
    I18n.reload!
  end

  include I18n::Test::Backend

  def test_1000_returns_hash
    assert_equal( {:interpolation=>"Interpolated text '%{var}'"}, I18n.t("extended", :locale => "default") )
  end
end
