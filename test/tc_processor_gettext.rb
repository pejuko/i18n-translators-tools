# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#

class TestProcessorGettext < Test::Unit::TestCase

  def setup
    # prepare object with correct data from yaml
    @tr = I18n::Translate::Translate.new('cze', {:locale_dir => $src_dir, :default_format => 'yml', :format => 'yml'})
    @tr.assign(@tr.target)

    # prepare reader and writer
    @trg_file = File.join($trg_dir, "cze.po")
    @src = I18n::Translate::Processor::Gettext.new(File.join($src_dir, "cze.po"), @tr)
    @trg = I18n::Translate::Processor::Gettext.new(@trg_file, @tr)

    # some data for comparation
    @si = {
        "comment" => "Comment",
        "extracted_comment" => "Extracted Comment",
        "reference" => "src/test.rb:31",
        "file" => "src/test.rb",
        "line" => "31",
        "fuzzy" => true,
        "flag" => "incomplete",
        "old_default" => "Previous untranslated",
        "default" => "Interpolated text '%{var}'",
        "translation" => "Interpolovaný text '%{var}'"
    }
  end

  def test_0010_read
    data = @src.read
    assert( data.keys.include?('cze') )
    data = data['cze']
    #diff(@si, data["simple"]["interpolation"])
    assert_equal( @si, data["simple"]["interpolation"] )
  end

  def test_0020_write
    data = @src.read
    @trg.write(data)
    assert( File.exists?(@trg_file) )
    data2 = @trg.read
    assert_equal(data, data2)
    File.unlink(@trg_file)
  end

end
