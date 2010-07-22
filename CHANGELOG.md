v0.2.0
======

* **format change** Instead of "t" use "translation" and instead of
  "old" use "old_default". Old format will be, however, supported as a
  shorthand. The i18n-translate tool will always save files in new format.

* **merge leave out unknown fields**

* **backend PO** Use this backend if you want to use po files managed with
  i18n-translate utility or now also natural po. If you
  want to use natural po files from gettext make your app.pot default
  and then you can use i18n.t("some text there") or create alias.

      I18n::Backend::Simple.send(:include, I18n::Backend::PO)
      def _(*args); I18n.t(*args); end

* **PO attributes** Now are supported (understand remain untouched) extra
  attributes #. (extracted comment) and #: (reference)

* **added support for TS format** If your translators want to use QT Linguist
  for translations. Convert to this format.

* **TS backend** if you want to use this format in your application use
  TS backend

      I18n::Backend::Simple.send(:include, I18n::Backend::TS)

* **java properties format supported**

      I18n::Backend::Simple.send(:include, I18n::Backend::Properties)


v0.1.1
======

* fix: gem dependencies
* file locking: should be thread safe


<!--
vi: filetype=mkd
-->
