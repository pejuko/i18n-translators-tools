# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Backend

  # to use Java properties files you should just include this backend
  #
  # I18n::Backend::Simple.send(:include, I18n::Backend::Properties)
  module Properties
  protected
    def load_properties(fname)
      locale = ::File.basename(fname, '.properties')
      tr = I18n::Translate::Translate.new(locale, {:empty => true})
      data = I18n::Translate::Processor::Properties.new(fname, tr).read
    end
  end
end
