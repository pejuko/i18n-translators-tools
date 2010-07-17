# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

require 'fileutils'
require 'find'

# I18n::Translate introduces new format for translations. To make
# I18n.t work properly you need to include Translator's backend:
#
#   I18n::Backend::Simple.send(:include, I18n::Backend::Translate)
#   I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
#
# notice that Translator have to be included BEFORE Fallbacks otherwise
# the fallback will get Hash (even with empty translation) and won't work.
#
# It is hightly recommended to use Fallbacks backend together with Translate.
# If you have experienced nil or empty translations this can fix the problem.
#
# Format of entry:
#
#   old: old default string
#   default: new default string
#   comment: translator's comments
#   t: translation
#   line: the lines, where is this key used # not implemented yet
#   flag: ok || incomplete || changed || untranslated
#   fuzzy: true # exists only where flag != ok (nice to have when you want
#                 edit files manualy)
#
# This format is for leaves in the tree hiearchy for plurals it should look like
#
#  key:
#    one:
#      old:
#      default:
#      t:
#      ...
#    other:
#      old:
#      default:
#      t:
#      ...
#
module I18n::Translate

  FLAGS = %w(ok incomplete changed untranslated)
  FORMATS = %w(yml rb po)       # the first one is preferred if :format => auto

  # returns flat array of all keys e.g. ["system.message.ok", "system.message.error", ...]
  def self.hash_to_keys(hash, separator=".", prefix="")
    res = []
    hash.keys.each do |key|
      str = prefix.empty? ? key : "#{prefix}#{separator}#{key}"
      if hash[key].kind_of?(Hash)
        str = hash_to_keys( hash[key], separator, str )
      end
      res << str
    end
    res.flatten
  end

  # returns what is stored under key
  def self.find(key, hash, separator=".")
    h = hash
    path = key.to_s.split(separator)
    path.each do |key|
      h = h[key]
      return nil unless h
    end
    h
  end

  def self.set(key, value, hash, separator=".")
    h = hash
    path = key.to_s.split(separator)
    path[0..-2].each do |chunk|
      h[chunk] ||= {}
      h = h[chunk]
    end
    unless value
      h[path[-1]] = nil
    else
      h[path[-1]] = value
    end
  end

  # scans :locale_dir for files with valid formats and returns
  # list of files with locales. If block is given then
  # it creates Translate object for each entry and pass it to the block
  def self.scan(opts=Translate::DEFAULT_OPTIONS, &block)
    o = Translate::DEFAULT_OPTIONS.merge(opts)
    o[:exclude] ||= []

    entries = []
    if o[:deep] == true
      Find.find(o[:locale_dir]) {|e| entries << e}
    else
      entries = Dir[File.join(o[:locale_dir], "*")]
    end

    locales = []
    entries.each do |entry|
      locale, format = Translate.valid_file?(entry, o[:format])
      if (not format) or (locale == o[:default])
        puts "#{entry}...skipping" if o[:verbose]
        next unless format
        next if locale == o[:default]
      end

      exclude = false
      o[:exclude].each do |ex|
        if entry =~ %r|#{ex}|
          exclude = true
          break
        end
      end
      puts "#{entry}...excluded" if exclude and o[:verbose]
      next if exclude

      locales << entry 
      dir = File.dirname(entry)

      if block
        yield Translate.new(locale, o.merge({:format => format, :locale_dir => dir, :default => o[:default]}))
      end

    end

    locales
  end



  # it breaks proc and lambdas objects
  class Translate
    DEFAULT_OPTIONS = {
      :separator => ".",       # default key separator e.g. "model.article.message.not.found"
      :locale_dir => "locale", # where to search for files
      :default => "default",   # default name for file containing default app's key => string
      :force_encoding => true, # in ruby 1.9 forces string encoding
      :encoding => "utf-8",    # encoding name to be forced to
      :format => "auto"        # auto, rb, yml
    }

    attr_reader :default, :target, :merge, :options, :lang, :default_file, :lang_file

    # loads default and lang files
    def initialize(lang, opts={})
      @lang = lang.to_s
      raise "Empty locale" if @lang.empty? and not opts[:empty]
      @options = DEFAULT_OPTIONS.merge(opts)
      @options[:default_format] ||= @options[:format]

      if @lang and not opts[:empty]
        @default, @default_file = load_locale( @options[:default], @options[:default_format] )
        @target, @lang_file = load_locale( @lang )
        merge!
      end
    end

    # check if the file has supported format
    def self.valid_file?(fname, format=Translate::DEFAULT_OPTIONS[:format])
      pattern = ".*?"
      pattern = format if format != "auto"
      fname =~ /\/?([^\/]*?)\.(#{pattern})$/
      locale, format = $1, $2
      if I18n::Translate::FORMATS.include?($2)
        return [locale, format]
      end
      nil
    end

    # will merge only one key and returns hash
    #   {
    #     :key => 'key',
    #     :default => '',              # value set in default file
    #     :old_default => '',          # value set as old in target file
    #                                    (value from default file from last translation
    #                                     if the field has changed)
    #     :old_t => '',                # if flag == 'changed' then old_t = t and t = ''
    #     :t => '',                    # value set in target file
    #     :line => 'some/file.rb: 44', # name of source file and number of line
    #                                    (a copy in target file from default file)
    #                                    !!! line is unused for now
    #     :comment => ''               # a comment added by a translator
    #     :flag => ok || incomplete || changed || untranslated    # set by merging tool except incomplete
    #                                                               which is set by translator
    #   }
    def [](key)
      d = I18n::Translate.find(key, @default, @options[:separator])
      raise "Translate#[key]: wrong key '#{key}'" unless d

      entry = {"key" => key, "default" => d}
      
      # translation doesn't exist
      trg = I18n::Translate.find(key, @target, @options[:separator])
      if (not trg) or
         (trg.kind_of?(String) and trg.strip.empty?) or
         (trg.kind_of?(Hash) and trg["t"].to_s.strip.empty?)
        entry["old_default"] = ""
        entry["old_t"] = ""
        entry["t"] = ""
        entry["comment"] = trg.kind_of?(Hash) ? trg["comment"].to_s.strip : ""
        entry["flag"] = "untranslated"
        return entry
      end

      # default has changed => new translation is probably required
      if trg.kind_of?(Hash)
        entry["old_t"] = trg["t"].to_s.strip
        entry["t"] = ""
        entry["comment"] = trg["comment"].to_s.strip
        entry["flag"] = "changed"

        if d != trg["default"]
          entry["old_default"] = trg["default"].to_s.strip
          return entry
        elsif not trg["old"].to_s.strip.empty?
          entry["old_default"] =  trg["old"].to_s.strip
          return entry
        end
      end

      # nothing has changed 
      entry["old_default"] = trg.kind_of?(Hash) ? trg["old"].to_s.strip : ""
      entry["old_t"] = ""
      entry["t"] = trg.kind_of?(Hash) ? trg["t"].to_s.strip : trg.to_s.strip
      entry["comment"] = trg.kind_of?(Hash) ? trg["comment"].to_s.strip : ""
      entry["flag"] = (trg.kind_of?(Hash) and trg["flag"]) ? trg["flag"].to_s.strip : "ok"

      entry
    end

    # wrapper for I18n::Translate.find with presets options
    def find(key, hash=@translate, separator=@options[:separator])
      I18n::Translate.find(key, hash, separator)
    end

    # will create path in @target for 'key' and set the 'value'
    def []=(key, value)
      I18n::Translate.set(key, value, @target, @options[:separator])
    end

    # merge merged and edited hash into @target
    # translation can be hash or array
    # * array format is the same as self.merge is
    #   [ {key => , t =>, ...}, {key =>, ...}, ... ]
    # * hash format is supposed to be the format obtained from web form
    #   {:key => {t =>, ...}, :key => {...}, ...}
    def assign(translation)
      translation.each do |transl|
        key, values = nil
        if transl.kind_of?(Hash)
          # merge format: [{key => , t =>, ...}, ...]
          key, values = transl["key"], transl
        elsif transl.kind_of?(Array)
          # web format: {key => {t => }, ...}
          key, values = transl
        end

        old_t = values["old_t"].to_s.strip
        new_t = values["t"].to_s.strip
        default = values["default"].to_s.strip
        old_default = values["old_default"].to_s.strip
        flag = values["flag"].to_s.strip
        comment = values["comment"].to_s.strip

        if old_t.respond_to?("force_encoding") and @options[:force_encoding]
          enc = @options[:encoding]
          old_t.force_encoding(enc)
          new_t.force_encoding(enc)
          default.force_encoding(enc)
          old_default.force_encoding(enc)
          flag.force_encoding(enc)
          comment.force_encoding(enc)
        end

        trg = {
          "comment" => comment,
          "flag" => flag
        }

        if flag == "ok"
          trg["t"] = new_t.empty? ? old_t : new_t
          trg["default"] = default
          trg["old"] = "" 
        else
          trg["t"] = new_t.empty? ? old_t : new_t
          trg["default"] = default
          trg["old"] = old_default
        end

        # make fallback work
        trg["t"] = nil if trg["t"].empty?

        # say that this entry is not completed yet
        # useful if you edit files in text editor and serching for next one
        trg["fuzzy"] = true if flag != "ok"

        self[key] = trg
      end
    end

    # re-read @target data from the disk and create @merge
    def reload!
      @target, @lang_file  = load_locale( @lang )
      merge!
    end

    # merge @default and @target into list @merge
    def merge!
      @merge = merge_locale
    end

    # export @target to file
    def export!
      save_locale(@lang)
    end

    # throw away translators metadata and convert
    # hash to default I18n format
    def strip!
      keys = I18n::Translate.hash_to_keys(@default, @options[:separator])
      keys.each do |key|
        entry = I18n::Translate.find(key, @target, @options[:separator])
        raise "Translate#[key]: wrong key '#{key}'" unless entry
        next unless entry.kind_of?(Hash)
        self[key] = entry["t"]
      end
  
      self
    end

    # returns statistics hash
    # {:total => N, :ok => N, :changed => N, :incomplete => N, :untranslated => N, :fuzzy => N, :progress => N}
    def stat
      stat = {
        :total => @merge.size,
        :ok => @merge.select{|e| e["flag"] == "ok"}.size,
        :changed => @merge.select{|e| e["flag"] == "changed"}.size,
        :incomplete => @merge.select{|e| e["flag"] == "incomplete"}.size,
        :untranslated => @merge.select{|e| e["flag"] == "untranslated"}.size,
        :fuzzy => @merge.select{|e| e["flag"] != "ok"}.size
      }
      stat[:progress] = (stat[:ok].to_f / stat[:total].to_f) * 100
      stat
    end

    def to_yaml
      trg = {@lang => @target}
      #YAML.dump(trg)
      trg.ya2yaml
    end

    def to_rb
      trg = {@lang => @target}
      trg.to_rb
    end

  protected

    # returns first file for @lang.type
    def file_name(lang, type=@options[:format])
      fname = "#{@options[:locale_dir]}/#{lang}.#{type}"
      if type == "auto"
        pattern = "#{@options[:locale_dir]}/#{lang}.*"
        fname = Dir[pattern].select{|x| Translate.valid_file?(x)}.first
      end
      fname = "#{@options[:locale_dir]}/#{lang}.#{FORMATS.first}" unless fname
      fname
    end

    # loads locales from .rb or .yml file
    def load_locale(lang, type=@options[:format])
      fname = file_name(lang, type)

      if File.exists?(fname)
        return [Processor.read(fname, self)[lang], fname]
      else
        STDERR << "Warning: I18n::Translate#load_locale: file `#{fname}' does NOT exists. Creating empty locale.\n"
      end

      [{}, fname]
    end

    # save to the first file found as lang.*
    # detects .rb and .yml
    def save_locale(lang)
      fname = file_name(lang)
      backup(fname)
      Processor.write(fname, {@lang => @target}, self)
    end

    # backup file if file exists
    def backup(fname)
      FileUtils.cp(fname, "#{fname}.bak") if File.exists?(fname)
    end

    # creates array of hashes as specified in self[] function
    def merge_locale
      keys = I18n::Translate.hash_to_keys(@default, @options[:separator])
      keys.sort!
      keys.inject([]) do |sum, key|
        sum << self[key]
      end
    end


  end # class Translate
end # module DML
