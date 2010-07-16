# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Translate::Processor

  class Gettext < Template
    FORMAT = ['po']

  protected

    def import(data)
      hash = {}

      entry = {}
      key = nil
      last = nil
      data.each_line do |line|
        # empty line starts new entry
        if line =~ %r{^\s*$}
          if not entry.empty? and key
            I18n::Translate.set(key, entry, hash, @translate.options[:separator])
          end
          key = nil
          last = nil
          entry = {}
          next
        end
        
        case line

        # translator's comment
        when %r{^# (.*)$}
          entry["comment"] = $1.to_s.strip

        # translator's comment
        when %r{^#: (.*)$}
          entry["line"] = $1.to_s.strip

        # flag
        when %r{^#, (.*)$}
          flags = $1.split(",").compact.map{|x| x.strip}
          fuzzy = flags.delete("fuzzy")
          unless fuzzy
            entry["flag"] = "ok"
          else
            flags.delete_if{|x| not I18n::Translate::FLAGS.include?(x)}
            entry["flag"] = flags.first unless flags.empty?
          end

        # old default
        when %r{^#\| msgid (.*)$}
          entry["old"] = $1.to_s.strip

        # key
        when %r{^msgctxt "(.*)"$}
          key = $1.to_s.strip
          last = "key"

        # default
        when %r{^msgid "(.*)"$}
          last = "default"
          entry[last] = $1.to_s.strip

        # translation
        when %r{^msgstr "(.*)"$}
          last = "t"
          entry[last] = $1.to_s.strip

        # string continuation
        when %r{^"(.*)"$}
          if last == "key"
            key = "#{key}#{$1.to_s.strip}"
          elsif last
            entry[last] = "#{entry[last]}#{$1.to_s.strip}"
          end
        end
      end

      # last line at end of file
      if not entry.empty? and key
        I18n::Translate.set(key, entry, hash, @translate.options[:separator])
      end

      {@translate.lang => hash}
    end


    # this export ignores data
    def export(data)
      str = ""
      keys = I18n::Translate.hash_to_keys(@translate.default).sort

      keys.each do |key|
        entry = [""]
        value = @translate.find(key, @translate.target)
        next unless value

        if value.kind_of?(String)
          entry << %~msgctxt #{key.inspect}~
          entry << %~msgid #{@translate.find(key, @translate.default).to_s.inspect}~
          entry << %~msgstr #{value.to_s.inspect}~
        else
          entry << %~#  #{value["comment"]}~ unless value["comment"].to_s.empty?
          entry << %~#: #{value["line"]}~ unless value["line"].to_s.empty?
          flags = []
          flags << "fuzzy" if value["fuzzy"]
          flags << value["flag"] unless value["flag"].to_s.strip.empty?
          entry << %~#, #{flags.join(", ")}~ unless flags.empty?
          entry << %~#| msgid #{value["old"]}~ unless value["old"].to_s.empty?
          entry << %~msgctxt #{key.inspect}~
          entry << %~msgid #{value["default"].to_s.inspect}~
          entry << %~msgstr #{value["t"].to_s.inspect}~
        end

        entry << ""

        str << entry.join("\n")
      end

      str
    end

  end

end
