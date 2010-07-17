# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Backend
  module PO
  protected
    def load_po(fname)
      locale = ::File.basename(fname, '.po')
      tr = I18n::Translate::Translate.new(locale, {:empty => true})
      data = I18n::Translate::Processor::Gettext.new(fname, tr).read
    end
  end
end
