v0.2.0
======

* **format change** Instead of "t" use "translation" and instead of
  "old" use "old_default". Old format will be, however, supported as a
  shorthand. The i18n-translate tool will always save files in new format.

* **added support for TS format** If your translators want to use QT Linguist
  for translations. Convert to this format.

* **backend PO** Use this backend if you want use po files managed with
  i18n-translate utility with I18n.t

* **PO attributes** Now are supported (understand remain untouched) extra
  attributes like #. (extracted comment) and #: (reference)
