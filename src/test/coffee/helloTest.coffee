# helloTest.coffee

should = require "should"

MODULE_UNDER_TEST = "../lib/hello"

mut = require MODULE_UNDER_TEST

describe "hello", ->
  it "should provide a friendly message", ->
    mut.MESSAGE.should.eql "Hello, world!\n"
