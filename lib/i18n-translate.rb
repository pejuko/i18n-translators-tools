# -*- coding: utf-8 -*-
# vi: fenc=utf-8:expandtab:ts=2:sw=2:sts=2
# 
# @author: Petr Kovar <pejuko@gmail.com>

require 'i18n'

dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir) unless $:.include?(dir)

require 'i18n/backend/translate'
require 'i18n/backend/po'
require 'i18n/backend/ts'
require 'i18n/backend/properties'
require 'i18n/processor'
require 'i18n/translate'

