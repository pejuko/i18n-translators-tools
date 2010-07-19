# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

require 'yaml'
require 'ya2yaml'

module I18n::Translate::Processor
  class YAML < Template
    FORMAT = ['yml', 'yaml']

  protected

    def import(data)
      migrate(::YAML.load(data))
    end

    def export(data)
      data.ya2yaml
    end

  end
end
