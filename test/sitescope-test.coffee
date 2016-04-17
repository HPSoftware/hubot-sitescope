chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'sitescope', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()
