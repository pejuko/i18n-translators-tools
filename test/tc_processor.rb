# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#

class TestProcessor < Test::Unit::TestCase

  def test_0010_dont_find_processor
    processor = I18n::Translate::Processor.find_processor("test.abc")
    assert_equal( nil, processor )
  end

  def test_0010_find_processor_yaml
    # yml
    processor = I18n::Translate::Processor.find_processor("test.yml")
    assert_equal( I18n::Translate::Processor::YAML, processor )

    # yaml
    processor = I18n::Translate::Processor.find_processor("test.yaml")
    assert_equal( I18n::Translate::Processor::YAML, processor )
  end

  def test_0010_find_processor_ruby
    processor = I18n::Translate::Processor.find_processor("test.rb")
    assert_equal( I18n::Translate::Processor::Ruby, processor )
  end

  def test_0010_find_processor_gettext
    # po
    processor = I18n::Translate::Processor.find_processor("test.po")
    assert_equal( I18n::Translate::Processor::Gettext, processor )

    # pot
    processor = I18n::Translate::Processor.find_processor("test.pot")
    assert_equal( I18n::Translate::Processor::Gettext, processor )
  end

  def test_0010_find_processor_ts
    processor = I18n::Translate::Processor.find_processor("test.ts")
    assert_equal( I18n::Translate::Processor::TS, processor )
  end

  def test_0010_find_processor_properties
    processor = I18n::Translate::Processor.find_processor("test.properties")
    assert_equal( I18n::Translate::Processor::Properties, processor )
  end

end
