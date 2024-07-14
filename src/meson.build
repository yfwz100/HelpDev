helpdev_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
  'browser.vala',
  'sidebar.vala',
  'doc_list_model.vala'
]

helpdev_deps = [
  dependency('glib-2.0'),
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('webkitgtk-6.0'),
  dependency('libxml-2.0'),
]

helpdev_sources += gnome.compile_resources('helpdev-resources',
  'helpdev.gresource.xml',
  c_name: 'helpdev'
)

executable('helpdev', helpdev_sources,
  dependencies: helpdev_deps,
       install: true,
)
