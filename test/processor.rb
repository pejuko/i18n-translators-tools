# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Test

  module Processor

    def __prepare(processor, file)
      # prepare object with correct data from yaml
      @tr = I18n::Translate::Translate.new('cze', {:locale_dir => $src_dir, :default_format => 'yml', :format => 'yml'})
      @tr.assign(@tr.merge)

      # prepare reader and writer
      @src_file = File.join($src_dir, file)
      @trg_file = File.join($trg_dir, file)
      @src = processor.new(@src_file, @tr)
      @trg = processor.new(@trg_file, @tr)
    end

    def test_0010_read
      data = @src.read
      assert( data.keys.include?('cze') )
      data = data['cze']
      diff($si, data["extended"]["interpolation"])
      assert_equal( $si, data["extended"]["interpolation"] )
    end

    def test_0020_write
      data = @src.read
      @trg.write(data)
      assert( File.exists?(@trg_file) )
      data2 = @trg.read
      diff(data['cze'],data2['cze'])
      assert_equal(data, data2)
      File.unlink(@trg_file)
    end

  end

end
