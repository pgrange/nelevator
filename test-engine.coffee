require('source-map-support').install()

nodeunit = require('nodeunit')

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

exports.basics = nodeunit.testCase
  testShouldReturnNextCall: (test) ->
    engine.scenario [{from: 2,to: [1]},{from: 3,to: [2]}]
    engine.reset '12043'
  
    test.deepEqual engine.get('12043'),
      event: "call"
      floor: 2
  
    test.deepEqual engine.get('12043'),
      event: "call"
      floor: 3
  
    test.done()
  
  testShouldRotateThroughScenario: (test) ->
    engine.scenario [{from: 2,to: [1]}]
    engine.reset '12043'
  
    test.deepEqual engine.get('12043'),
      event: "call"
      floor: 2
  
    test.deepEqual engine.get('12043'),
      event: "call"
      floor: 2
  
    test.done()
  
  testShouldAcceptNothingScenarioSteps: (test) ->
    engine.scenario [null]
    engine.reset '12043'
  
    test.deepEqual engine.get('12043'),
      event: "nothing"
  
    test.done()
  
  testPeopleShouldGoInIfOpenAtFloor: (test) ->
    engine.scenario [{from: 0,to: [1]},null]
    engine.reset '12043'
    engine.put('12043', 'OPEN')
  
    test.deepEqual engine.get('12043'),
      event: "enter"
      people: 1
  
    test.done()
  
  testPeopleShouldPressButtonWhenIn: (test) ->
    engine.scenario [{from: 1,to: [2]},null,null]
    engine.reset '12043'
    engine.put('12043', 'UP')
    engine.put('12043', 'OPEN')
    engine.get('12043') #people enter
  
    test.deepEqual engine.get('12043'),
      event: "go"
      floor: 2
  
    test.done()
  
  testPeopleShouldGoOutIfOpenAtFloor: (test) ->
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
  
  testEngineShouldSupportBlindElevators: (test) ->
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
  
  testFIXWhenPeopleAreInTheyAreIn: (test) ->
    engine.scenario [{from: 0,to: [1]},null,null,null,null]
    engine.reset '12043'
    engine.put('12043', 'OPEN')
  
    test.deepEqual engine.get('12043'),
      event: "enter"
      people: 1
  
    test.deepEqual engine.get('12043'),
      event: "go"
      floor: 1
  
    test.deepEqual engine.get('12043'),
      event: "nothing"
  
    test.done()
  
  testFIXDoNotFailWhenNoOneEverWaitedAtFloorAndOpen: (test) ->
    engine.scenario [{from: 1,to: [2]},null,null,null,null]
    engine.reset '12043'
    engine.put('12043', 'OPEN')
  
    test.deepEqual engine.get('12043'),
      event: "nothing"
  
    test.done()

exports.checks = nodeunit.testCase
  testShouldFailWhenGettingForUnexistingElevator: (test) ->

    test.throws(() ->
      engine.get('12034')
    , engine.Uninitialized)

    test.done()

  testShouldFailWhenMovingUPWithDoorsOpen: (test) ->

    test.throws(() ->
      engine.reset('12043')
      engine.put('12043', 'OPEN')
      engine.put('12043', 'UP') #sprouitch
    , engine.DoorsOpenMove)

    test.done()

  testShouldFailWhenMovingDownWithDoorsOpen: (test) ->

    test.throws(() ->
      engine.reset('12043')
      engine.put('12043', 'OPEN')
      engine.put('12043', 'DOWN') #sprouitch
    , engine.DoorsOpenMove)

    test.done()

  testShouldFailForUnknownCommands: (test) ->

    test.throws(() ->
      engine.reset('12043')
      engine.put('12043', 'DTC')
    , engine.UnknownCommand)

    test.done()

  testShouldFailWhenNotResettingAfterError: (test) ->
    
    engine.reset('12043')
    try
      engine.put('12043', 'DTC')
    catch
      # ignore

    test.throws(() ->
      engine.get('12043')
    , engine.Uninitialized)

    test.done()

  testShouldFailWhenDiggingThroughTheGround: (test) ->
    engine.building {min: 0,max: 0}
    engine.reset('12043')

    test.throws(() ->
      engine.put('12043', 'DOWN')
    , engine.NoSuchFloor)

    test.done()

  testShouldFailWhenFlyingOverTheCeiling: (test) ->
    engine.building {min: 0,max: 0}
    engine.reset('12043')

    test.throws(() ->
      engine.put('12043', 'UP')
    , engine.NoSuchFloor)

    test.done()

exports.scoring = nodeunit.testCase
  # 1 people reaching its floor : + 10
  # elevator crashing           : -100
  testElevatorStartsWithZeroPoints: (test) ->
    engine.reset('zero')

    test.equals 0, engine.score('zero')

    test.done()

  testElevatorGainPointsWhenPeopleReachTheirFloor: (test) ->
    engine.scenario([{from: 0, to: [0, 0]},null,null])
    engine.reset('1people')
    engine.put('1people', 'OPEN')
    engine.put('1people', 'CLOSE')
    engine.put('1people', 'OPEN')
    engine.get('1people')

    test.equals 20, engine.score('1people')

    test.done()

  testElevatorLoosePointsForInvalidMove: (test) ->
    engine.reset('crash')
    try
      engine.put('crash', 'DOWN')
    catch
      #ignore

    test.equals -100, engine.score('crash')

    test.done()
