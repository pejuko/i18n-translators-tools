# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n

  module Backend
    # It is highly recommended to use Translator wit Fallback plugin
    #
    #   I18n::Backend::Simple.send(:include, I18n::Backend::Translator)
    #   I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    #
    # notice that Translator have to be included BEFORE Fallback otherwise
    # the fallback will get Hash (even with empty translation) and won't work.
    module Translate

      # wrapper which can work with both format
      # the simple and the Translator's
      def translate(locale, key, options = {})
        result = super(locale, key, options)
        return result unless result.kind_of?(Hash)
        return nil unless result[:t]

        tr = result[:t]
        values = options.except(*I18n::Backend::Base::RESERVED_KEYS)

        tr = resolve(locale, key, tr, options)
        tr = interpolate(locale, tr, values) if values

        tr
      end

    end # module Backend::Translator
  end # module Backend

end

