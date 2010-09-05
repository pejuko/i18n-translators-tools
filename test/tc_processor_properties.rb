# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>


class TestProcessorProperties < Test::Unit::TestCase

  def setup
    __prepare(I18n::Translate::Processor::Properties, "cze.properties")
  end

  include I18n::Test::Processor


  def test_0010_read
    data = @src.read
    assert( data.keys.include?('cze') )
    data = data['cze']
    str = "Interpolovaný text '%{var}'"
    #diff(str, data["extended"]["interpolation"])
    assert_equal( str, data["extended"]["interpolation"] )
  end

  def test_0020_write_keeps_extra_keys
    data = @src.read
    @trg.write(data)
    assert( File.exists?(@trg_file) )
    data2 = @trg.read
    diff(data, data2)
    assert_equal(data, data2)
    File.unlink(@trg_file)
  end

  def test_0030_write_throw_away_extra_keys_by_merge
    data = @src.read
    @trg.write(data)
    assert( File.exists?(@trg_file) )
    data2 = @trg.read
    diff(data, data2)
    assert_not_equal(data, data2)
    File.unlink(@trg_file)
  end

end
