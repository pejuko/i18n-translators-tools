# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>
#

class TestBackendTS < Test::Unit::TestCase

  def setup
    I18n.load_path = Dir[ "#{$src_dir}/default.yml", "#{$src_dir}/cze.ts" ]
    I18n.reload!
  end

  include I18n::Test::Backend

end
