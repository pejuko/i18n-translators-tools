# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Backend

  # to use po files generated (e.g: by merge) by i18n-translate you should
  # include this backend istead of I18n::Backend::Gettext
  #
  # I18n::Backend::Simple.send(:include, I18n::Backend::PO)
  module PO
  protected
    def load_po(fname)
      locale = ::File.basename(fname, '.po')
      tr = I18n::Translate::Translate.new(locale, {:empty => true})
      data = I18n::Translate::Processor::Gettext.new(fname, tr).read
    end
  end
end
