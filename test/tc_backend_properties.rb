# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#

class TestBackendProperties < Test::Unit::TestCase

  def setup
    I18n.load_path = Dir[ "#{$src_dir}/default.yml", "#{$src_dir}/cze.properties" ]
    I18n.reload!
  end

  include I18n::Test::Backend

  def test_1000_colon_as_assign_operator
    assert_equal( "apple, banana, pear, cantaloupe, watermelon, kiwi, mango", I18n.t("fruits") )
  end

  def test_1010_space_at_key_begining
    assert_equal( "Beauty", I18n.t("Truth") )
  end

  def test_1020_escaped_operators_in_key
    assert_equal( "operators", I18n.t("esc=aped:operators") )
  end

  def test_1030_key_without_assign_and_value
    assert_equal( "translation missing: cze, empty_key", I18n.t("empty_key") )
  end

end
