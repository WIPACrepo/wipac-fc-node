# Cakefile
#----------------------------------------------------------------------

BROWSER_COMMAND = "firefox --new-tab"

#----------------------------------------------------------------------------

{exec} = require "child_process"

#----------------------------------------------------------------------------

task "check", "Check dependency versions", ->
  project = require "./package.json"
  for dependency of project.dependencies
    checkVersion dependency, project.dependencies[dependency]
  for dependency of project.devDependencies
    checkVersion dependency, project.devDependencies[dependency]

task "clean", "Remove build cruft", ->
  clean()

task "coverage", "Perform test coverage analysis", ->
  clean -> compile -> test -> coverage()

task "rebuild", "Rebuild the module", ->
  clean -> compile -> test()

#----------------------------------------------------------------------------

clean = (next) ->
  exec "rm -fR lib/* test/*", (err, stdout, stderr) ->
    throw err if err
    next?()

compile = (next) ->
  exec "node_modules/.bin/coffee -o lib/ -c src/main/coffee", (err, stdout, stderr) ->
    throw err if err
    exec "node_modules/.bin/coffee -o test/ -c src/test/coffee", (err, stdout, stderr) ->
      throw err if err
      next?()

coverage = (next) ->
  exec "node_modules/.bin/istanbul cover node_modules/.bin/_mocha -- --recursive", (err, stdout, stderr) ->
    throw err if err
    exec "#{BROWSER_COMMAND} coverage/lcov-report/index.html", (err, stdout, stderr) ->
      throw err if err
      next?()

test = (next) ->
  exec "node_modules/.bin/mocha --colors --recursive", (err, stdout, stderr) ->
    console.log stdout + stderr
    next?() if stderr.indexOf("AssertionError") < 0

#----------------------------------------------------------------------------

checkVersion = (dependency, version) ->
  exec "npm --json info #{dependency}", (err, stdout, stderr) ->
    depInfo = JSON.parse stdout
    if depInfo["dist-tags"].latest isnt version
      console.log "[OLD] #{dependency} is out of date #{version} vs. #{depInfo["dist-tags"].latest}"

#----------------------------------------------------------------------------
# end of Cakefile
