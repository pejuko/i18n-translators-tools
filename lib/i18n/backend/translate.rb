# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n

  module Backend
    # It is highly recommended to use Translator wit Fallback plugin
    #
    #   I18n::Backend::Simple.send(:include, I18n::Backend::Translate)
    #   I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    #
    # notice that Translator have to be included BEFORE Fallback otherwise
    # the fallback will get Hash (even with empty translation) and won't work.
    module Translate

      # wrapper which can work with both format
      # the simple and the Translator's
      def translate(locale, key, options = {})
        raise InvalidLocale.new(locale) unless locale
        entry = key && lookup(locale, key, options[:scope], options)
        entry = translate_to_i18n(entry)

        if options.empty?
          entry = resolve(locale, key, entry, options)
        else
          count, default = options.values_at(:count, :default)
          values = options.except(*RESERVED_KEYS)
          entry = entry.nil? && default ?
              default(locale, key, default, options) : resolve(locale, key, entry, options)
        end

        throw(:exception, I18n::MissingTranslation.new(locale, key, options)) if entry.nil?
        entry = entry.dup if entry.is_a?(String)

        entry = pluralize(locale, entry, count) if count
        entry = translate_to_i18n(entry) # after pluralization there can be enhanced format
        entry = entry.dup if entry.is_a?(String)
        entry = interpolate(locale, entry, values) if values

        #throw(:exception, I18n::MissingTranslation.new(locale, key, options)) if entry.to_s.empty?

        entry
      end

      protected

      def translate_to_i18n(entry)
        if entry.is_a?(Hash) && (entry[:translation] || entry[:t] || entry[:default])
          entry = entry[:translation] || entry[:t] || entry[:default]
        end
        entry
      end

    end # module Backend::Translator
  end # module Backend

end

