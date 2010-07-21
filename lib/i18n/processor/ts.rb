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

    def get(xml, path, key=nil)
      elements = []
      xml.elements.each(path) {|e| elements << e}
      element = elements.first
      ret = ""
      ret = element.get_text.to_s if element and not key
      ret = element.attributes[key].to_s.strip if element and key
      ret.gsub!("&apos;", "'")
      ret = uninspect(::CGI::unescapeHTML(ret))
      ret
    end

    def import(data)
      hash = {}
      xml = ::REXML::Document.new(data)
      lang = @translate.lang
      lang = get(xml, "TS", "language").to_s.strip if lang.empty?
      xml.elements.each("//TS/context") do |context|
        key = get(context, "name")
        context.elements.each("message") do |message|
          entry = {}
          entry["file"] = get(message, "location", "filename").to_s.strip
          entry["line"] = get(message, "location", "line").to_s.strip
          if key.to_s.strip.empty?
            # this happen if you use linguist on converting po to ts
            # context is saved as a comment
            key = get(message, "comment").to_s.strip
            raise "No key for message: #{message.to_s}" if key.empty?
          end
          entry["default"] = get(message, "source")
          entry["old_default"] = get(message, "oldsource")
          entry["extracted_comment"] = get(message, "extracomment").to_s.strip
          entry["comment"] = get(message, "translatorcomment").to_s.strip
          entry["translation"] = get(message, "translation")
          fuzzy = get(message, "translation", "type").to_s.strip
          entry["fuzzy"] = true unless fuzzy.empty?
          flag = get(message, "extra-po-flags").to_s.strip
          entry["flag"] = flag unless flag.empty?
          entry.delete_if {|k,v| v.to_s.empty?}
          I18n::Translate.set(key, entry, hash, @translate.options[:separator])
          key = nil
        end
      end
      {lang => hash}
    end


    # serialize hash to XML
    def export(data, indent=0)
      target = data[@translate.lang]
      xml = <<EOF
<?xml version="1.0" encoding="#{@translate.options[:encoding]}"?>
<!DOCTYPE TS>
<TS version="2.0" language="#{@translate.lang}">
EOF

      keys = I18n::Translate.hash_to_keys(@translate.default).sort
      keys.each do |key|
        value = @translate.find(key, target)

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
          fuzzy = ((value["flag"] == "ok") or value["flag"].to_s.strip.empty?) ? "" : %~ type="unfinished"~
          xml += <<EOF
    <context>
        <name>#{::CGI.escapeHTML(key)}</name>
        <message>
EOF
          if value["file"] or value["line"]
            xml += <<EOF
            <location filename="#{::CGI.escapeHTML(value["file"].to_s)}" line="#{::CGI.escapeHTML(value["line"].to_s)}" />
EOF
          end
          xml += <<EOF
            <source>#{::CGI.escapeHTML(value["default"].to_s)}</source>
EOF
          unless value["old_default"].to_s.empty?
            xml += <<EOF
            <oldsource>#{::CGI.escapeHTML(value["old_default"].to_s)}</oldsource>
EOF
          end
          unless value["extracted_comment"].to_s.empty?
            xml += <<EOF
            <extracomment>#{::CGI.escapeHTML(value["extracted_comment"].to_s)}</extracomment>
EOF
          end
          unless value["comment"].to_s.empty?
            xml += <<EOF
            <translatorcomment>#{::CGI.escapeHTML(value["comment"].to_s)}</translatorcomment>
EOF
          end
          xml += <<EOF
            <translation#{fuzzy}>#{::CGI.escapeHTML(value["translation"].to_s)}</translation>
EOF
          unless value["flag"].to_s.strip.empty?
            xml += <<EOF
            <extra-po-flags>#{::CGI.escapeHTML(value["flag"].to_s.strip)}</extra-po-flags>
EOF
          end
          xml += <<EOF
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
