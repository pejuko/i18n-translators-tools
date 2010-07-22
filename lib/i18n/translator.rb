# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Translate

  class Translator
    def initialize(lang, opts={})
      @translate = I18n::Translate::Translate.new(lang, opts)
    end

    def run
      stat = @translate.stat
      @translate.merge.select{|x| x["flag"] != "ok"}.each_with_index do |entry, i|
        next_entry = false
        while not next_entry
          puts ""
          puts ""
          puts "[#{@translate.default_file} + #{@translate.lang_file}]"
          puts "(#{i+1}/#{stat[:fuzzy]}) #{entry["key"]} (#{entry["flag"]})"
          puts "comment: #{entry["comment"]}" unless entry["comment"].empty?
          puts "old default: #{entry["old_default"]}" unless entry["old_default"].empty?
          puts "old translation: #{entry["old_translation"]}" unless entry["old_translation"].empty?
          puts "default: #{entry["default"]}"
          puts "translation: #{entry["translation"]}"
          puts ""
          puts "Actions:"
          puts "n (next) t (translate) f (change flag) c (comment) s (save) q (save & quit) x(exit no saving)"
          action = STDIN.readline.strip
          puts ""
          case action
          when 'n'
            next_entry = true
          when 't'
            puts "Enter translation:"
            entry["translation"] = STDIN.readline.strip
            entry["flag"] = "ok" unless entry["translation"].empty?
            @translate.assign( [entry] )
            puts "Flag sets to #{entry["flag"]}"
          when 'f'
            puts "Change flag to:"
            puts "o (ok), i (incomplete), c (changed), u (untranslated)"
            f = STDIN.readline.strip
            I18n::Translate::FLAGS.each do |fname|
              if fname[0,1] == f
                entry["flag"] = fname
                break
              end
            end
            @translate.assign( [entry] )
            puts "Flag sets to #{entry["flag"]}"
          when 'c'
            puts "Enter comment:"
            entry["comment"] = STDIN.readline.strip
            @translate.assign( [entry] )
            puts "Comment has changed."
          when 's'
            @translate.export!
            puts "Translation saved"
          when 'q'
            @translate.export!
            puts "Translation saved"
            exit
          when 'x'
            exit
          end # case
        end # while
      end # each_with_index
    
      @translate.export!
      @translate.reload!
    end
  end

end
