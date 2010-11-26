require 'rubygems'
require 'lib/i18n-translate'
require 'pp'

opts = {:locale_dir => 'test/locale/src', :locale => 'cze', :format => 'po', :default => 'cze'}
tr = I18n::Translate::Translate.new('cze', opts)
fname = opts[:locale_dir] + "/" + opts[:locale] + "." + opts[:format]

pr = I18n::Translate::Processor::Gettext

COUNT = 1000

bt = Time.now
COUNT.times do |i|
  processor = pr.new(fname, tr)
  processor.read
end
et = Time.now

puts "Regular Time: #{et-bt}"
