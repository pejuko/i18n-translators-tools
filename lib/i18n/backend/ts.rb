# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Backend

  # to use QT linguist TS files you should just include this backend
  #
  # I18n::Backend::Simple.send(:include, I18n::Backend::TS)
  module TS
  protected
    def load_ts(fname)
      locale = ::File.basename(fname, '.ts')
      tr = I18n::Translate::Translate.new(locale, {:empty => true})
      data = I18n::Translate::Processor::TS.new(fname, tr).read
    end
  end
end
