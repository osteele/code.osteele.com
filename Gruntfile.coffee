module.exports = (grunt) ->
  grunt.initConfig

    directories:
      build: '<%= directories.dev %>'
      dev: 'build'
      release: 'release'
      ':release':
        build: '<%= directories.release %>'

    clean:
      dev: '<%= directories.dev %>'
      release: '<%= directories.release %>/*'
      target: '<%= directories.build %>/*'

    coffeelint:
      app: ['**/*.coffee', '!**/node_modules/**', '!Gruntfile.coffee']
      gruntfile: 'Gruntfile.coffee'
      options:
        max_line_length: value: 120

    connect:
      server: options: base: '<%= directories.build %>'

    copy:
      app:
        expand: true
        src: ['css/*', 'images/*', '!**/*.{coffee,jade,sass,scss}']
        dest: '<%= directories.build %>'
        filter: 'isFile'

    'gh-pages':
      options: base: '<%= directories.build %>'
      src: '**/*'

    jade:
      app:
        expand: true
        src: ['**/*.jade', '!node_modules/**/*']
        dest: '<%= directories.build %>'
        ext: '.html'
      options:
        pretty: true
        ':release':
          pretty: false

    sass:
      app:
        expand: true
        dest: '<%= directories.build %>'
        src: ['css/**.scss']
        ext: '.css'
      options:
        sourcemap: true
        ':release':
          sourcemap: false
          style: 'compressed'

    watch:
      options:
        livereload: true
      copy:
        files: ['css/**/*.css']
        tasks: ['copy']
      gruntfile:
        files: 'Gruntfile.coffee'
        tasks: ['coffeelint:gruntfile']
      jade:
        files: ['app/**/*.jade']
        tasks: ['jade']
      sass:
        files: ['app/**/main.scss']
        tasks: ['sass']

  require('load-grunt-tasks')(grunt)

  grunt.registerTask 'build', ['clean:target', 'jade', 'sass', 'copy']
  grunt.registerTask 'build:release', ['contextualize:release', 'build']
  grunt.registerTask 'deploy', ['build:release', 'gh-pages']
  grunt.registerTask 'default', ['build', 'connect', 'watch']
