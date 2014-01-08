exports.config =
  modules:
    definition: false
    wrapper: false
  paths:
    public: "build/"
  files:
    stylesheets:
      joinTo:
        'css/app.css': /^(app|vendor)(?:\/|\\)[^_]/
  plugins:
    jaded:
      jade:
        pretty: yes
