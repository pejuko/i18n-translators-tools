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
        result = super(locale, key, options)
        return nil if result.kind_of?(String) and result.empty?
        return result unless result.kind_of?(Hash)
        return nil unless result[:t] or result[:translation] or result[:default]

        tr = result[:translation] || result[:t]
        tr = result[:default] if tr.to_s.empty?

        return nil if tr.to_s.empty?

        values = options.except(*RESERVED_KEYS)

        tr = resolve(locale, key, tr, options)
        tr = interpolate(locale, tr, values) if values

        tr
      end

    end # module Backend::Translator
  end # module Backend

end

