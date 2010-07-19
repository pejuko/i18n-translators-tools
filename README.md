I18n translation and locales management utility
===============================================

This package brings you useful utility which can help you to handle locale files
and translations in your Ruby projects.


Interesting features
--------------------

* no database required
* merging and changes propagation (adding, removing and changed default text)
  keeping default file untouched
* creating new locale file based on another (usually default) file
* converting from one format to another (yml <=> rb <=> po)
* statistics
* built-in simple console translator
* support for locales split into sub-directories like:
  * locale
    * controller
      * main
        * default.yml
        * en_US.yml
        * en_GB.yml
        * cs_CZ.yml
      * auth
        * default.yml
        * en_US.yml
        * en_GB.yml
        * cs_CZ.yml
    * model
      * user
        * default.yml
        * en_US.yml
        * en_GB.yml
        * cs_CZ.yml
    * rules
      * en_US.rb
      * en_GB.yml
      * cs_CZ.rb
* adds extra translation metadata right to the locale files (translators whose
  translate with text editors don't have to tackle with diffs)
* can strip all extra metadata and revert back to the
  I18n::Backend::Simple format
* in configuration files
  (~/.config/ruby/i18n-translate; locale/.i18n-translate) you can put your
  common or project related configurations (e.g: exclude => ['rules'])
  i18n-translate utility reads firstly config in your home 
  (~/.config/ruby/i18n-translate) then merge it with the one in your project
  locale directory (e.g: locale/.i18n-translate) and then change it
  using command line arguments


WARNING
-------

* **i18n-translate can NOT handle lambdas and procedures.** The solution is to
  put all your rules to separate file and use exclude (repeatable) argument
  or create configuration file for your project in locales directory including
  exclude array.
* **po files are supported only partialy.** If you convert from yaml or ruby to
  po and back you don't have to care even if you are using pluralization.
  If you are converting from po origin files then you can lose header of the
  file, pluralization, some flags (fuzzy will stay) and previous-context.
  Strings over multiple lines are supported, however.
* **po files are not compatible with I18n::Backedn::Gettext.** The main purpose
  of enabling conversions to po files is effort to allow usage of many po
  editors for ruby projects. You can either keep all your files in yml and
  convert them only for translators and then back or you can have default in
  yml and other locales in po files. i18-translate tool will take care of it.

Installation
------------

**RubyGems**

    gem install i18n-translators-tools

**Latest from sources***

    git clone git://github.com/pejuko/i18n-translators-tools.git
    cd i18n-translators-tools
    rake gem
    gem install pkg/i18n-translators-tools.gem


How to add support into your application
----------------------------------------

i18n-translate brings additional metadata to locales. Therefore you have to
include new backend into I18n. This new backend works as a transparent proxy
and can work with both simple and enhanced format. If you are already using
I18n then adding this backend will be probably the only change you have to do.
I highly recommend to use this extension together with Fallback backend
and all default values (usually in english) put into special file like
'default.yml'.

This will enable to have locales like en_US and en_GB where
can native speakers put their polished english. I think it is good thing 
to put all default strings into separate file(s). If you need to change
some text you don't have to touch source code.

Default files have to be in the I18n simple format. The enhanced format
is only for locales.

So in your application you should do something like this:

    require 'i18n-translate'

    I18n::Backend::Simple.send(:include, I18n::Backend::Translate)
    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.default_locale = 'default'
    I18n.load_path << Dir[ File.expand_path("../locale/*.yml", __FILE__) ]

and then you can use

    I18n.t('some.key', :count => 3, :var => 'interpolated string')

as usual.

Notice that Translator have to be included BEFORE Fallbacks
otherwise the fallback will get Hash (even with empty translation)
and won't work.

It is hightly recommended to use Fallbacks backend together with
Translate. If you have experienced nil or empty translations due to
untranslated strings this can fix the problem.


Examples
--------

Suppose we have our locales in 'locale/' directory without sub-directories and
default values are inside 'locale/default.yml' file. And we have two files
with locales 'locale/de_DE.yml', 'locale/cs_CZ.yml' and 'locale/extra/cs_CZ.yml'

**Merging new changes (additions, removes, field changes) to all files:**

    $> i18n-translate merge
    locale/cs_CZ.yml...merged
    locale/de_DE.yml...merged

**Converting all cs_CZ files to rb format:**

    $> i18n-translate convert -f yml -t rb -l cs_CZ -r
    locale/cs_CZ.yml...converted
    locale/extra/cs_CZ.yml...converted

**Show some statistics:**

    $> i18n-translate stat
    locale/cs_CZ.yml...65% (650/1000)
    locale/de_DE.yml...90% (900/1000)

**PO locales and default.yml**

    $> i18n-translate merge
    locale/cs_CZ.po...merged
    locale/de_DE.po...merged

**Translate more entries (built-in translator invocation):**

    $> i18n-translate translate -l cs_CZ

For more help run i18n-translate without parameters.

There also exists example web application. It is simple web standalone
translator. You can download it at [i18n-web-translator][1]


Supported formats
-----------------

* **po**; supported format looks like

		#  there is some comment
                #. extracted-comment
                #: reference
		#, fuzzy, changed
		#| msgid Old default
		msgctxt "there.is.some.key"
		msgid "Default text"
		msgstr "Prelozeny defaultni text"

  Such po file is pretty usable with po editors.

  To use po files generated (e.g: by merge) with i18n-translate you should
  include this backend istead of I18n::Backend::Gettext
 
      I18n::Backend::Simple.send(:include, I18n::Backend::PO)

* **yml**; standard yaml files in I18n simple format
* **rb**; typical ruby files in I18n simple format
* **ts**; QT Linguist TS format. If you are planing to do translation in
  qt linguist, convert to this format rather then to po. Include TS backend
  if you want use this foramat for locales.

      I18n::Backend::Simple.send(:include, I18n::Backend::TS)


New locale files format
------------------------

Old format using in Simple backend is:

    key: "String"

or for pluralization (depends on rules) it can be similar to this:

    key:
      one: "String for one"
      other: "plural string"

New format looks like:

    key:
      old_default: "old default string"
      default: "new default string"
      comment: "translator's comments"
      translation: "translation itself"
      flag: "one of (ok || incomplete || changed || untranslated)"
      fuzzy: true # exists only where flag != ok (nice to have when you want
                    edit files manually)

Pluralized variant should look like:

    key:
      one:
        old_default:
        default:
        translation:
        ...
      other:
        old_default:
        default:
        translation:
        ...

As you can see the old format is string and the new format is hash.
If you use lambdas and procs objects, you should save them in separate
file(s) because i18n-translate utility can't handle them but Translate backend
can.


Configure file format
-------------------

Configuration files are normal ruby files which should return hash.
It is not necessary to use all switches.

**Example config file:**

    {
      :exclude => ['rules'],
      :format => 'yml',
      :default => 'en_US'
      :default_format => 'rb',
      :verbose => true,
      :locale_dir => 'locales',
      :separator => '.',
      :target => 'yml',
      :deep => true,
      :force_encoding => true,
      :encoding => 'utf-8',
      :quiet => false
    }

[1]: http://github.com/pejuko/i18n-web-translator

