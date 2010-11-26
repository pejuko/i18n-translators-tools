# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#

class TestProcessorTS < Test::Unit::TestCase

  def setup
    __prepare(I18n::Translate::Processor::TS, "cze.ts")
  end

  include I18n::Test::Processor

    def test_1010_read_po_to_ts
      t = I18n::Translate::Translate.new('cze', {:locale_dir => $src_dir, :default_format => 'yml', :format => 'yml'})
      file = File.join($src_dir, 'po_to_ts.ts')
      reader = I18n::Translate::Processor::TS.new(file, t)
      data = reader.read
      assert( data.keys.include?('cze') )
      data = data['cze']
      diff($si, data["extended"]["interpolation"])
      assert_equal( $si, data["extended"]["interpolation"] )
    end

end
