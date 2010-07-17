# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

require 'rexml/document'
require 'cgi'

module I18n::Translate::Processor

  class TS < Template
    FORMAT = ['ts', 'qt']

  protected

    def import(data)
    end


    # serialize hash to XML
    def export(data, indent=0)
      xml = <<EOF
<?xml version="1.0" encoding="#{@translate.options[:encoding]}"?>
<!DOCTYPE TS>
<TS version="2.0" language="#{@translate.lang}">
EOF

      keys = I18n::Translate.hash_to_keys(@translate.default).sort
      keys.each do |key|
        value = @translate.find(key, @translate.target)

        if value.kind_of?(String)
          fuzzy = (value.to_s.empty?) ? %~ type="unfinished"~ : ""
          xml += <<EOF
    <context>
        <name>#{::CGI.escapeHTML(key)}</name>
        <message>
          <source>#{::CGI.escapeHTML(@translate.find(key, @translate.default).to_s)}</source>
          <translation#{fuzzy}>#{::CGI.escapeHTML(value.to_s)}</translation>
        </message>
    </context>
EOF
        else
          fuzzy = (value["flag"] == "ok") ? "" : %~ type="unfinished"~
          xml += <<EOF
    <context>
      <name>#{::CGI.escapeHTML(key)}</name>
      <message>
          <source>#{::CGI.escapeHTML(value["default"].to_s)}</source>
EOF
          unless value["old"].to_s.empty?
            xml += <<EOF
          <oldsource>#{::CGI.escapeHTML(value["old"].to_s)}</oldsource>
EOF
          end
          unless value["comment"].to_s.empty?
            xml += <<EOF
          <translatorcomment>#{::CGI.escapeHTML(value["comment"].to_s)}</translatorcomment>
EOF
          end
          xml += <<EOF
          <translation#{fuzzy}>#{::CGI.escapeHTML(value["t"].to_s)}</translation>
          <extra-po-flags>#{::CGI.escapeHTML(value["flag"].to_s)}</extra-po-flags>
      </message>
    </context>
EOF
        end
      end

      xml += <<EOF
</TS>
EOF
      xml
    end

  end

end
