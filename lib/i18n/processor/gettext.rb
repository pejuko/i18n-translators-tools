# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Translate::Processor

  class Gettext < Template
    FORMAT = ['po', 'pot', 'gettext']

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

        # extracted comment
        when %r{^#\. (.*)$}
          entry["extracted_comment"] = $1.to_s.strip

        # reference
        when %r{^#: (.*)$}
          entry["reference"] = $1.to_s.strip
          if entry["reference"] =~ %r{^(.*):(\d+)$}
            entry["file"] = $1.to_s.strip
            entry["line"] = $2.to_s.strip
          end

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
        when %r{^#\| msgid "(.*)"$}
          entry["old_default"] = $1.to_s

        # key (context)
        when %r{^msgctxt "(.*)"$}
          key = $1.to_s.strip
          last = "key"

        # default
        when %r{^msgid "(.*)"$}
          if $1.to_s.strip.empty?
            last = "po-header"
          else
            last = "default"
            entry[last] = $1.to_s
          end

        # translation
        when %r{^msgstr "(.*)"$}
          last = "translation"
          entry[last] = $1.to_s

        # string continuation
        when %r{^"(.*)"$}
          if last == "key"
            key = "#{key}#{$1}"
          elsif last == "po-header"
            case $1
            when %r{^Content-Type: text/plain; charset=(.*)$}
              enc = $1.to_s.strip
              @translate[:encoding] = enc unless enc.empty?
            when %r{^X-Language: (.*)$}
              # skip language is set from filename
            end
          elsif last
            entry[last] = "#{entry[last]}#{$1}"
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

      str << %~msgid ""\n~
      str << %~msgstr ""\n~
      str << %~"Content-Type: text/plain; charset=#{@translate.options[:encoding]}\\n"\n~
      str << %~"X-Language: #{@translate.lang}\\n"\n~
      keys.each do |key|
        entry = [""]
        value = @translate.find(key, @translate.target)
        next unless value

        if value.kind_of?(String)
          entry << %~msgctxt #{key.inspect}~
          entry << %~msgid #{@translate.find(key, @translate.default).to_s.inspect}~
          entry << %~msgstr #{value.to_s.inspect}~
        else
          entry << %~#  #{value["comment"].to_s.strip}~ unless value["comment"].to_s.strip.empty?
          entry << %~#. #{value["extracted_comment"].to_s.strip}~ unless value["extracted_comment"].to_s.strip.empty?
          if not value["reference"].to_s.strip.empty?
            entry << %~#: #{value["reference"].to_s.strip}~
          elsif value["file"] or value["line"]
            entry << %~#: #{value["file"].to_s.strip}:#{value["line"].to_s.strip}~
          end
          flags = []
          flags << "fuzzy" if (not value["flag"].nil?) and (value["flag"] != "ok")
          flags << value["flag"] unless value["flag"].to_s.strip.empty?
          entry << %~#, #{flags.join(", ")}~ unless flags.empty?
          entry << %~#| msgid #{value["old_default"].to_s.inspect}~ unless value["old_default"].to_s.empty?
          entry << %~msgctxt #{key.inspect}~
          entry << %~msgid #{value["default"].to_s.inspect}~
          entry << %~msgstr #{value["translation"].to_s.inspect}~
        end

        entry << ""

        str << entry.join("\n")
      end

      str
    end

  end

end
