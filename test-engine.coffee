require('source-map-support').install()

engine = require('./engine')

# GET /<id>
# -> return next event for elevator <id> as a JSON object.
#    Return HTTP/400 if elevator is not in a state to
#    receive new event. For instance if it has not made
#    any move between two GET requests.
#
#    Event can be one of call, go, enter, exit or nothing.
#    * elevator called at second floor :
#    { "event": "call",
#      "floor": 2 }
#
#    * elevator asked to go to third floor :
#    { "event": "go",
#      "floor": 3 }
#
#    * 2 people have entered the elevator :
#    { "event": "enter",
#      "people": 2 }
#
#    * 1 people have exited the elevator :
#    { "event": "exit",
#      "people": 1 }
#
#    * nothing happened :
#    { "event": "nothing" }
#
# PUT /<id>
# -> Creates or reset an elevator. This will result
#    in elevator <id> being a brand new elevator
#    places at floor 0 with doors closed.
#
# PUT /<id>/<command>
# -> receive next command of the elevator <id>.
#    Return HTTP/200 for valid command.
#    Return HTTP/400 for invalid command, for instance if
#    elevator is asking to go higher than the last floor.
#
#    Command can be one of UP, DOWN, OPEN, CLOSE
#
# WARNING ! An elevator should ask for next event before
# sending a command every time. Or it may loose some events.
# This sequence :
# GET /12043
# PUT /12043/UP
# PUT /12043/UP
# Is equivalent to this sequence but ignoring second GET :
# GET /12043
# PUT /12043/UP
# GET /12043
# PUT /12043/UP

exports.testShouldReturnNextCall = (test) ->
  engine.scenario [{from: 2,to: [1]},{from: 3,to: [2]}]
  engine.reset '12043'

  test.deepEqual engine.get('12043'),
    event: "call"
    floor: 2

  test.deepEqual engine.get('12043'),
    event: "call"
    floor: 3

  test.done()

exports.testShouldRotateThroughScenario = (test) ->
  engine.scenario [{from: 2,to: [1]}]
  engine.reset '12043'

  test.deepEqual engine.get('12043'),
    event: "call"
    floor: 2

  test.deepEqual engine.get('12043'),
    event: "call"
    floor: 2

  test.done()

exports.testShouldAcceptNothingScenarioSteps = (test) ->
  engine.scenario [null]
  engine.reset '12043'

  test.deepEqual engine.get('12043'),
    event: "nothing"

  test.done()

exports.testPeopleShouldGoInIfOpenAtFloor = (test) ->
  engine.scenario [{from: 0,to: [1]},null]
  engine.reset '12043'
  engine.put('12043', 'OPEN')

  test.deepEqual engine.get('12043'),
    event: "enter"
    people: 1

  test.done()

exports.testPeopleShouldPressButtonWhenIn = (test) ->
  engine.scenario [{from: 0,to: [1]},null]
  engine.reset '12043'
  engine.put('12043', 'OPEN')
  engine.get('12043') #people enter

  test.deepEqual engine.get('12043'),
    event: "go"
    floor: 1

  test.done()

exports.testPeopleShouldGoOutIfOpenAtFloor = (test) ->
  engine.scenario [{from: 0,to: [1]},null,null,null]
  engine.reset '12043'
  engine.put('12043', 'OPEN')
  engine.get('12043') #people enter
  engine.put('12043', 'CLOSE')
  engine.get('12043') #people ask to go to 1
  engine.put('12043', 'UP')
  engine.put('12043', 'OPEN')

  test.deepEqual engine.get('12043'),
    event: "exit"
    people: 1

  test.done()

exports.testEngineShouldSupportBlindElevators = (test) ->
  engine.scenario [{from: 0,to: [1]},null,null,null,null]
  engine.reset '12043'
  engine.put('12043', 'OPEN')
  engine.put('12043', 'CLOSE') #people entered just before this PUT
  engine.put('12043', 'UP')    #people asked to go to 1 just before this PUT
  engine.put('12043', 'OPEN')

  test.deepEqual engine.get('12043'),
    event: "exit"
    people: 1

  test.done()
