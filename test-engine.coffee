require('source-map-support').install()

nodeunit = require('nodeunit')

engine = require('./engine')

exports.basics = nodeunit.testCase
  setUp: (done) ->
    engine.purge()
    done()

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
  setUp: (done) ->
    engine.purge()
    done()

  testShouldFailWhenGettingForUnexistingElevator: (test) ->

    test.throws(() ->
      engine.get('12043')
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
  setUp: (done) ->
    engine.purge()
    done()

  testElevatorStartsWithZeroPoints: (test) ->
    engine.reset('12043')

    test.equals 0, engine.score('12043')

    test.done()

  testElevatorGainPointsWhenPeopleReachTheirFloor: (test) ->
    engine.scenario([{from: 0, to: [0, 0]},null,null])
    engine.reset('12043')
    engine.put('12043', 'OPEN')
    engine.put('12043', 'CLOSE')
    engine.put('12043', 'OPEN')
    engine.get('12043')

    test.equals 20, engine.score('12043')

    test.done()

  testElevatorLoosePointsForInvalidMove: (test) ->
    engine.reset('12043')
    try
      engine.put('12043', 'DOWN')
    catch
      #ignore

    test.equals -100, engine.score('12043')

    test.done()

  testScoresDoNotContainElevatorId: (test) ->
    engine.purge()
    engine.scenario [{from: 0, to: [1, 2]},null,null,null,null]
    engine.reset('1')
    engine.reset('2')
    engine.put('2', 'OPEN')
    engine.put('2', 'CLOSE')
    engine.put('2', 'UP')
    engine.put('2', 'OPEN')
    engine.put('2', 'CLOSE')
    engine.reset('3')
    engine.put('3', 'OPEN')
    engine.put('3', 'CLOSE')
    engine.put('3', 'UP')
    engine.put('3', 'OPEN')
    engine.put('3', 'CLOSE')
    engine.put('3', 'UP')
    engine.put('3', 'OPEN')
    engine.put('3', 'CLOSE')
 
    test.deepEqual engine.scores(), [
      name: 'John Do'
      score: 0
    ,
      name: 'John Do'
      score: 10
    ,
      name: 'John Do'
      score: 20
    ]

    test.done()

  testOneCanGiveANameToItsElevatorToDisplayInScores: (test) ->
    engine.purge()
    engine.reset('12043', 'Best elevator ever !')

    test.deepEqual engine.scores(), [
      name: 'Best elevator ever !'
      score: 0
    ]

    test.done()

  testElevatorShouldKeepItsNameAfterReset: (test) ->
    engine.purge()
    engine.reset('12043', 'Best elevator ever !')
    engine.reset('12043')

    test.deepEqual engine.scores(), [
      name: 'Best elevator ever !'
      score: 0
    ]

    test.done()

exports.timeout = nodeunit.testCase
  setUp: (done) ->
    engine.purge()
    done()

  testPeopleUseStairsOrDieAfterTooMuchTimeWaiting: (test) ->
    engine.patience(1)
    engine.scenario [{from: 0, to: [1]}, null, null,null]
    engine.reset('12043')
    engine.get('12043') #people called
    engine.get('12043') #people waited one tick... already bored

    engine.put('12043', 'OPEN') #too late

    test.deepEqual engine.get('12043'),
      event: "nothing"
 
    test.done()
