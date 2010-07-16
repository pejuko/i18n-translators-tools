# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

module I18n::Translate::Processor

  class Ruby < Template
    FORMAT = ['rb']

  protected

    def import(data)
      eval(data)
    end

    # serialize hash to string
    def export(data, indent=0)
      str = "{\n"
  
      data.keys.sort{|k1,k2| k1.to_s <=> k2.to_s}.each_with_index do |k, i|
        str << ("  " * (indent+1))
        str << "#{k.inspect} => "
        if data[k].kind_of?(Hash)
          str << export(data[k], indent+1)
        else
          str << data[k].inspect
        end
        str << "," if i < (data.keys.size - 1)
        str << "\n"
      end
  
      str << ("  " * (indent))
      str << "}"
  
      str
    end

  end

end
