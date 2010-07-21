# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Translate::Processor

  class Properties < Template
    FORMAT = ['properties', 'java']

  protected

    def import(data)
      hash = {}

      key = nil
      value = nil
      line_number = 0
      data.each_line do |line|
        line_number += 1
        # skip empty line and comments
        next if (line =~ %r{^\s*$}) or (line =~ %r{^#.*})
        
        case line
        # multiline string
        when %r{^([^=]+)\s*=\s*(.*)\\$}
          key = $1.to_s.strip
          value = $2.to_s.strip

        # continuous multiline string
        when %r{^\s*([^=]+)\\$}
          value << $1.to_s.strip

        # end of continuous string
        when %r{^\s*([^=]+)$}
          value << $1.to_s.strip
          I18n::Translate.set(key, uninspect(value), hash, @translate.options[:separator])
          value = nil

        # simple key = value
        when %r{^([^=]+)\s*=\s*(.*)$}
          key, value = $1.to_s.strip, $2.to_s.strip
          I18n::Translate.set(key, uninspect(value), hash, @translate.options[:separator])
        end
      end

      {@lang => hash}
    end


    # this export ignores data
    def export(data)
      target = data[@translate.lang]
      str = ""
      keys = I18n::Translate.hash_to_keys(@translate.default).sort

      keys.each do |key|
        value = @translate.find(key, target)
        next unless value
        entry = ""


        if value.kind_of?(String)
          entry = value.strip
        else
          entry = value["translation"].to_s.strip
        end

        # create record in format: key = value
        str << key << " = " << entry << "\n"
      end

      str
    end

  end

end
