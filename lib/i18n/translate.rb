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
#   old_default: old default string
#   default: new default string
#   comment: translator's comments
#   translation: translation itself (optionaly in the file can be just t as
#                a shorthand, however, the tools will allways write translation)
#   extracted_comment: po compatibility
#   file: file where it is # po compatibility
#   line: the lines, where is this key used #  po compatibility
#   flag: ok || incomplete || changed || untranslated || obsolete
#   fuzzy: true # exists only where flag != ok (nice to have when you want
#                 edit files manualy)
#
# This format is for leaves in the tree hiearchy for plurals it should look like
#
#  key:
#    one:
#      old_default:
#      default:
#      translation:
#      ...
#    other:
#      old_default:
#      default:
#      translation:
#      ...
#
module I18n::Translate

  FLAGS = %w(ok incomplete changed untranslated obsolete)
  #FORMATS = %w(yml rb po pot ts properties)       # the first one is preferred if :format => auto
  # function I18n::Translate::Processor.init will register known
  # formats
  FORMATS = %w() # the first one is preferred if :format => auto
  RESERVED_WORDS = %w(comment extracted_comment reference file line default old_default fuzzy flag translation old t)

  # read configuration file
  # config format is ruby file which returns hash
  def self.read_config(filename)
    eval File.read(filename)
  end

  # checks if all keys are reserved keywords
  def self.is_enhanced?(hash)
    return false unless hash.kind_of?(Hash)
    hash.keys.each do |key|
      return false unless I18n::Translate::RESERVED_WORDS.include?(key)
    end
    true
  end

  # returns flat array of all keys e.g. ["system.message.ok", "system.message.error", ...]
  def self.hash_to_keys(hash, separator=".", prefix="")
    res = []
    hash.keys.each do |key|
      str = prefix.empty? ? key : "#{prefix}#{separator}#{key}"
      enhanced = I18n::Translate.is_enhanced?(hash[key])
      if hash[key].kind_of?(Hash) and (not enhanced)
        str = hash_to_keys( hash[key], separator, str )
      end
      res << str
    end if hash
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
      h.delete(path[-1])
    else
      h[path[-1]] = value
    end
  end

  def self.delete(key, hash, separator=".")
    path = key.split(separator)
    set(key, nil, hash, separator)
    i = path.size - 1
    while i >= 0
      k = path[0..i].join(separator)
      trg = find(k, hash, separator)
      if trg and trg.kind_of?(Hash) and trg.empty?
        set(k, nil, hash, separator)
      end
      i -= 1
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
        next
      end

      # skip if not desired locale
      if o[:locale] and (o[:locale] != "auto") and (o[:locale] != locale)
        puts "#{entry}...skipping" if o[:verbose]
        next 
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

  # create new locale and returns I18n::Translate::Translate object
  def self.create_locale(lang, opts={})
    tr = I18n::Translate::Translate.new(lang, opts)
    tr.assign(tr.merge)
    tr.export!
    tr
  end

  # it breaks proc and lambdas objects
  class Translate
    DEFAULT_OPTIONS = {
      :separator => ".",       # default key separator e.g. "model.article.message.not.found"
      :locale_dir => "locale", # where to search for files
      :default => "default",   # default name for file containing default app's key => string
      :force_encoding => true, # in ruby 1.9 forces string encoding
      :encoding => "utf-8",    # encoding name to be forced to
      :format => "auto",       # auto, rb, yml
      :merge => "soft",        # hard or soft: hard strips old keys from target and soft set it to obsolete
    }

    attr_reader :default, :target, :merge, :options, :lang, :default_file, :lang_file

    # loads default and lang files
    def initialize(lang, opts={})
      @lang = lang.to_s
      raise "Empty locale" if @lang.empty? and not opts[:empty]

      # merge options
      @options = DEFAULT_OPTIONS.merge(opts)

      # select default format
      @options[:default_format] ||= @options[:format]
      if (@options[:default_format] == @options[:format]) and not opts[:default_format]
        dfname = file_name(@options[:default], @options[:default_format])
        @options[:default_format] = "auto" unless File.exists?(dfname)
      end

      # load default data and translation
      if @lang and not opts[:empty]
        @default, @default_file = load_locale( @options[:default], @options[:default_format] )
        @target, @lang_file = load_locale( @lang )
        merge!
      end
    end

    # check if the file has supported format
    def self.valid_file?(fname, format=Translate::DEFAULT_OPTIONS[:format])
      pattern = "[^\.]+"
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
    #     'key' => 'key',
    #     'default' => '',              # value set in default file
    #     'old_default' => '',          # value set as old in target file
    #                                    (value from default file from last translation
    #                                    if the field has changed)
    #     'old_translation' => '',      # if flag == 'changed' then old_translation = t and t = ''
    #     'translation' => '',          # value set in target file
    #     'comment' => ''               # a comment added by a translator
    #     'flag' => ok || incomplete || changed || untranslated || obsolete
    #                                   # set by merging tool except incomplete
    #                                     which is set by translator
    #    # other keys helded for compatibility with other formats
    #   }
    def [](key)
      d = I18n::Translate.find(key, @default, @options[:separator])
      raise "Translate#[key]: wrong key '#{key}'" unless d

      entry = {"key" => key, "default" => d}
      
      # translation doesn't exist
      trg = I18n::Translate.find(key, @target, @options[:separator])
      if (not trg) or
         (trg.kind_of?(String) and trg.strip.empty?) or
         (trg.kind_of?(Hash) and trg["translation"].to_s.strip.empty?)
        entry["old_default"] = ""
        entry["old_translation"] = ""
        entry["translation"] = ""
        entry["comment"] = trg.kind_of?(Hash) ? trg["comment"].to_s.strip : ""
        entry["flag"] = "untranslated"
        return entry
      end

      # default has changed => new translation is probably required
      if trg.kind_of?(Hash)
        entry["old_translation"] = trg["translation"].to_s.strip
        entry["translation"] = ""
        entry["comment"] = trg["comment"].to_s.strip
        entry["flag"] = "changed"

        if d != trg["default"]
          entry["old_default"] = trg["default"].to_s.strip
          return entry
        elsif not trg["old_default"].to_s.strip.empty?
          entry["old_default"] =  trg["old_default"].to_s.strip
          return entry
        end
      end

      # nothing has changed 
      entry["old_default"] = trg.kind_of?(Hash) ? trg["old_default"].to_s.strip : ""
      entry["old_translation"] = ""
      entry["translation"] = trg.kind_of?(Hash) ? trg["translation"].to_s.strip : trg.to_s.strip
      entry["comment"] = trg.kind_of?(Hash) ? trg["comment"].to_s.strip : ""
      entry["flag"] = (trg.kind_of?(Hash) and trg["flag"]) ? trg["flag"].to_s.strip : "ok"

      entry
    end

    # wrapper for I18n::Translate.find with presets options
    def find(key, hash=@target, separator=@options[:separator])
      I18n::Translate.find(key, hash, separator)
    end

    def delete(key)
      I18n::Translate.delete(key, @default, @options[:separator])
      I18n::Translate.delete(key, @target, @options[:separator])
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

        old_t = values["old_translation"].to_s.strip
        new_t = values["translation"].to_s.strip
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

        # merging with unknown fields
        trg = find(key)
        trg = {} if trg.nil? or not trg.kind_of?(Hash)
        trg["comment"] = comment
        trg["flag"] = flag

        if flag == "ok"
          trg["translation"] = new_t.empty? ? old_t : new_t
          trg["default"] = default
          trg["old_default"] = "" 
        else
          trg["translation"] = new_t.empty? ? old_t : new_t
          trg["default"] = default
          trg["old_default"] = old_default
        end

        # make fallback work
        trg["translation"] = nil if trg["translation"].empty?

        # say that this entry is not completed yet
        # useful if you edit files in text editor and serching for next one
        trg["fuzzy"] = true if flag != "ok"

        # clean empty values
        trg.delete_if{ |k,v| v.to_s.empty? }

        self[key] = trg
      end
      obsolete!
    end

    def obsolete!(merge = @options[:merge])
      def_keys = I18n::Translate.hash_to_keys(@default, @options[:separator]).sort
      trg_keys = I18n::Translate.hash_to_keys(@target, @options[:separator]).sort

      obsolete_keys = trg_keys - def_keys
      obsolete_keys.each do |key|
        if merge == "hard"
          I18n::Translate.delete(key, @target, @options[:separator])
          next
        end

        trg = find(key)
        next unless trg

        if trg.kind_of?(String)
          trg = {"translation" => trg, "flag" => "obsolete"}
        else
          trg["flag"] = "obsolete"
          trg["fuzzy"] = true
        end

        I18n::Translate.set(key, trg, @target, @options[:separator])
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
        next unless entry # skip entries that are not merged in target yet
        #raise "Translate#[key]: wrong key '#{key}'" unless entry
        next unless entry.kind_of?(Hash)
        self[key] = entry["translation"]
      end
  
      self
    end

    # returns statistics hash
    # {:total => N, :ok => N, :changed => N, :obsolete => N, :incomplete => N, :untranslated => N, :fuzzy => N, :progress => N}
    def stat
      stat = {
        :total => @merge.size,
        :ok => @merge.select{|e| e["flag"] == "ok"}.size,
        :changed => @merge.select{|e| e["flag"] == "changed"}.size,
        :incomplete => @merge.select{|e| e["flag"] == "incomplete"}.size,
        :untranslated => @merge.select{|e| e["flag"] == "untranslated"}.size,
        :obsolete => @merge.select{|e| e["flag"] == "obsolete"}.size,
        :fuzzy => @merge.select{|e| e["flag"] != "ok"}.size
      }
      stat[:progress] = (stat[:ok].to_f / stat[:total].to_f) * 100
      stat
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
        data = Processor.read(fname, self)
        return [data[lang], fname]
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
