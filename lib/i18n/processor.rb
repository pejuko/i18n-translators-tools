# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Translate

  module Processor
    @processors = []

    class << self
      attr_reader :processors
    end

    # append processor to the registry
    def self.<<(processor)
      @processors << processor
    end

    # find processor for fname and use it to read data
    def self.read(fname, tr)
      processor = find_processor(fname)
      raise "Unknown file format" unless processor
      worker = processor.new(fname, tr)
      worker.read
    end

    # find processor for fname and use it to save data
    def self.write(fname, data, tr)
      processor = find_processor(fname)
      raise "Unknown file format `#{fname}'" unless processor
      worker = processor.new(fname, tr)
      worker.write(data)
    end

    # find appropriate processor for given file name
    def self.find_processor(fname)
      @processors.each do |processor|
        return processor if processor.can_handle?(fname)
      end
      nil
    end

    # register formats from all known processors
    def self.init(default='yml')
      @processors.each do |processor|
        processor.register(default)
      end
    end


    # this is abstract class for processors. processors should mainly implement
    # protected methdos import and export
    class Template
      FORMAT = []

      # register new processor
      def self.inherited(processor)
        Processor << processor
      end

      attr_reader :filename, :translate

      # initialize new processor
      def initialize(fname, tr)
        @filename = fname
        @translate = tr
        fname =~ %r{/?([^/]+)\.[^\.]+$}i
        @lang = $1.to_s.strip
      end

      # register proessors's formats
      def self.register(default='yml')
        self::FORMAT.each do |format|
          unless I18n::Translate::FORMATS.include?(format)
            # default format will be first
            if default == format
              I18n::Translate::FORMATS.unshift(format)
            else
              I18n::Translate::FORMATS << format
            end
          end
        end
      end

      # read file into hash
      def read
        data = File.open(@filename, mode("r")) do |f|
          f.flock File::LOCK_SH
          f.read
        end
        import(data)
      end

      # write hash to file
      def write(data)
        File.open(@filename, mode("w")) do |f|
          f.flock File::LOCK_EX
          f << export(data)
        end
      end

      # check if processor can handle this file
      def self.can_handle?(fname)
        fname =~ %r{\.([^\.]+)$}i
        self::FORMAT.include?($1)
      end

    protected

      # converts raw data from file to hash
      def import(data)
        data
      end

      # converts hash to raw
      def export(data)
        data
      end

      # converts inspected string back into normal string
      def uninspect(str)
        return nil unless str
        str.gsub(%r!\\([\\#"abefnrstvx]|u\d{4}|u\{[^\}]+\}|\d{1,3}|x\d{1,2}|cx|C-[a-zA-Z]|M-[a-zA-Z]| |=|:)!) do |m|
          repl = ""
          if ['\\', '#', '"'].include?($1)
            repl = $1
          else
            repl = eval("\"\\#{$1}\"")
          end
          repl
        end
      end

      # convert old, t shorthand fields
      def migrate(data)
        keys = I18n::Translate.hash_to_keys(data, @translate.options[:separator])
        keys.each do |key|
          entry = I18n::Translate.find(key, data, @translate.options[:separator])
          next unless I18n::Translate.is_enhanced?(entry)
          %w(old t).each do |prop|
            next unless entry[prop]
            value = entry.delete(prop)
            prop = case(prop)
                   when "old"
                     "old_default"
                   when "t"
                     "translation"
                   end
            entry[prop] = value
          end
          I18n::Translate.set(key, entry, data, @translate.options[:separator])
        end
        data
      end

      # in ruby 1.9 it sets encoding for opening IOs
      def mode(m)
        mode = m.dup
        mode << ":" << @translate.options[:encoding] if defined?(Encoding)
        mode
      end
    end
  end

end


require 'i18n/processor/yaml'
require 'i18n/processor/ruby'
require 'i18n/processor/gettext'
require 'i18n/processor/ts'
require 'i18n/processor/properties'


# initialize all registred processors
I18n::Translate::Processor.init
