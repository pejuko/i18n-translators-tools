# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Translate::Processor

  class Properties < Template
    FORMAT = ['properties']

    WHITE_SPACE = / |\n|\t|\f|\r|\\u0020|\\u0009|\\u000C/
    ASSIGN = /(?:#{WHITE_SPACE})*?(?:=|:)(?:#{WHITE_SPACE})*/
    KEY = /^((?:[^\\:=]|\\:|\\=|\\ )+?)/m
    VALUE_MULTILINE = /(.*?(?:\\\\)*)\\$/
    VALUE = /(.*?(?:\\\\)*$)/
    VALUE_END = /([^=]+?(?:\\\\)*$)/

  protected

    def import(data)
      hash = {}

      sep = @translate.options[:separator]
      plus_key = sep+"translation"
      key = nil
      value = nil
      status = :first
      line_number = 0
      data.each_line do |line|
        line_number += 1
        # skip empty line and comments (first non white character is # or !)
        next if (line =~ %r{^(#{WHITE_SPACE})*$}) or (line =~ %r{^(#{WHITE_SPACE})*(#|!).*})
        
        # multiline string
        if line[%r{#{KEY}#{ASSIGN}#{VALUE_MULTILINE}}] and (status == :first)
          status = :inside
          key = $1.to_s
          value = $2.to_s

        # continuous multiline string
        elsif line[%r{^(?:#{WHITE_SPACE})*#{VALUE_MULTILINE}}] and (status == :inside)
          value << $1.to_s

        # end of continuous string
        elsif line[%r{^(?:#{WHITE_SPACE})*#{VALUE_END}$}] and (status == :inside)
          value << $1.to_s.strip
          I18n::Translate.set(uninspect(key)+plus_key, uninspect(value), hash, sep)
          value = nil
          status = :first

        # simple key = value
        elsif line[%r{#{KEY}#{ASSIGN}#{VALUE}}]
          key, value = $1.to_s.strip, $2.to_s.strip
          I18n::Translate.set(uninspect(key)+plus_key, uninspect(value), hash, sep)

         # empty key
        elsif line[/#{KEY}\s*/]
          key = $1.to_s.strip
          value = ""
          I18n::Translate.set(uninspect(key)+plus_key, uninspect(value), hash, sep)
        else
          puts "*** not match: '#{line}'"
        end
      end

      {@lang => hash}
    end

    # this export ignores data
    def export(data)
      sep = @translate.options[:separator]
      target = data[@translate.lang]
      str = ""
      keys = I18n::Translate.hash_to_keys(target).sort

      keys.each do |key|
        value = @translate.find(key, target)
        next unless value
        entry = ""


        if value.kind_of?(String)
          entry = value
        else
          entry = value["translation"].to_s
        end

        k = key
        k = $1 if k =~ /(.*)#{Regexp.escape sep}translation$/

        # create record in format: key = value
        str << k.gsub(/( |:|=)/){|m| "\\#{m}"} << " = " << entry.gsub("\n", "\\n") << "\n"
      end

      str
    end

  end

end
