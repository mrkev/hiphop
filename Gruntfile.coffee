module.exports = (grunt) ->
    buildPlatforms = parseBuildPlatforms(grunt.option('platforms'))
    packageJson = grunt.file.readJSON('package.json')
    _VERSION = packageJson.version
    grunt.log.writeln 'Building ' + packageJson.version
    

    grunt.initConfig
        clean: ['build/releases/**']

        coffee:
            compileBare:
                options:
                    bare: true
                files:
                    'js/app.js': ['coffee/-*.coffee', 'coffee/app.coffee', 'coffee/_*.coffee']

        compass:
            dist:
                options:
                    cssDir: 'css'
                files:
                    'css/app.css': 'sass/app.sass'

        uglify:
            target:
                files:
                    'js/app.js': 'js/app.js'

        cssmin:
            minify:
                files:
                    'css/app.css': 'css/app.css'

        # Note: Watches only app, not website.
        watch:
            scripts:
                files: ['coffee/**/*.coffee']
                tasks: ['coffee']
                options:
                    interrupt: true

            stylesheets:
                files: ['sass/**/*.sass']
                tasks: ['compass']
                options:
                    interrupt: true
        shell:
            runnw:
                options:
                    stdout: true
                command: [
                    './build/cache/mac/0.9.2/node-webkit.app/Contents/MacOS/node-webkit . --debug'
                ,
                    '.\\build\\cache\\win\\0.9.2\\nw.exe . --debug'
                ].join('&')
            create_dmg:
                options:
                    stdout: true
                command: './dist/mac/yoursway-create-dmg/create-dmg --volname "HipHop ' + _VERSION + '" --background ./dist/mac/background.png --window-size 480 540 --icon-size 128 --app-drop-link 240 370 --icon "HipHop" 240 110 ./build/releases/HipHop/mac/HipHop-' + _VERSION + '.dmg ./build/releases/HipHop/mac/'

        'regex-replace':
            windows_installer:
                src: ['dist/win/windows-installer.iss']
                actions:
                    name: 'version'
                    search: '#define AppVersion "[\.0-9]+"'
                    replace: '#define AppVersion "' + _VERSION + '"'

        nodewebkit:
            options:
                build_dir: './build'
                mac_icns: './images/icon.icns'
                mac: buildPlatforms.mac
                win: buildPlatforms.win
                linux32: buildPlatforms.linux32
                linux64: buildPlatforms.linux64
            src: ['./css/**', './fonts/**', './images/**', './js/**', './node_modules/**', '!./node_modules/grunt*/**', './index.html', './package.json']

        copy:
            main:
                files: [
                    src: 'libraries/win/ffmpegsumo.dll'
                    dest: 'build/releases/HipHop/win/HipHop/ffmpegsumo.dll'
                    flatten: true
                ,
                    src: 'libraries/win/ffmpegsumo.dll'
                    dest: 'build/cache/win/<%= nodewebkit.options.version %>/ffmpegsumo.dll'
                    flatten: true
                ,
                    src: 'libraries/mac/ffmpegsumo.so'
                    dest: 'build/releases/HipHop/mac/HipHop.app/Contents/Frameworks/node-webkit Framework.framework/Libraries/ffmpegsumo.so'
                    flatten: true
                ,
                    src: 'libraries/mac/ffmpegsumo.so'
                    dest: 'build/cache/mac/<%= nodewebkit.options.version %>/node-webkit.app/Contents/Frameworks/node-webkit Framework.framework/Libraries/ffmpegsumo.so'
                    flatten: true
                ,
                    src: 'libraries/linux64/libffmpegsumo.so'
                    dest: 'build/releases/HipHop/linux64/HipHop/libffmpegsumo.so'
                    flatten: true
                ,
                    src: 'libraries/linux64/libffmpegsumo.so'
                    dest: 'build/cache/linux64/<%= nodewebkit.options.version %>/libffmpegsumo.so'
                    flatten: true
                ]
        compress:
            linux32:
                options:
                    mode: 'tgz'
                    archive: 'build/releases/HipHop/linux32/HipHop-' + _VERSION + '.tgz'
                expand: true
                cwd: 'build/releases/HipHop/linux32/'
                src: '**'
            linux64:
                options:
                    mode: 'tgz'
                    archive: 'build/releases/HipHop/linux64/HipHop-' + _VERSION + '.tgz'
                expand: true
                cwd: 'build/releases/HipHop/linux64/'
                src: '**'

    
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-clean'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-compass'
    grunt.loadNpmTasks 'grunt-contrib-uglify'
    grunt.loadNpmTasks 'grunt-contrib-cssmin'
    grunt.loadNpmTasks 'grunt-contrib-copy'
    grunt.loadNpmTasks 'grunt-shell'
    grunt.loadNpmTasks 'grunt-regex-replace'
    grunt.loadNpmTasks 'grunt-node-webkit-builder'
    grunt.loadNpmTasks 'grunt-contrib-compress'
    
    grunt.registerTask 'default', ['compass', 'coffee']
    grunt.registerTask 'obfuscate', ['uglify', 'cssmin']
    grunt.registerTask 'nodewkbuild', ['nodewebkit', 'copy']
    grunt.registerTask 'run', ['default', 'shell:runnw']
    grunt.registerTask 'build', ['default', 'obfuscate', 'clean', 'regex-replace', 'nodewkbuild', 'shell:create_dmg', 'compress']

parseBuildPlatforms = (argumentPlatform) ->
    
    # this will make it build no platform when the platform option is specified
    # without a value which makes argumentPlatform into a boolean
    inputPlatforms = argumentPlatform or process.platform + ';' + process.arch
    
    # Do some scrubbing to make it easier to match in the regexes bellow
    inputPlatforms = inputPlatforms.replace('darwin', 'mac')
    inputPlatforms = inputPlatforms.replace(/;ia|;x|;arm/, '')
    buildAll = /^all$/.test(inputPlatforms)
    buildPlatforms =
        mac: /mac/.test(inputPlatforms) or buildAll
        win: /win/.test(inputPlatforms) or buildAll
        linux32: /linux32/.test(inputPlatforms) or buildAll
        linux64: /linux64/.test(inputPlatforms) or buildAll

    buildPlatforms
