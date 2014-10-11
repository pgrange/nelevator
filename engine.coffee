scenario  = null
building  = null
elevators = null
scores    = null

exports.purge = () ->
  scenario = []
  building = {min: 0, max: 6}
  elevators = {}
  scores = {}
  exports.elevators = elevators #debug
exports.purge()

exports.scenario = (value) ->
  scenario = value

exports.building = (value) ->
  building = value

exports.reset = (id, name) ->
  elevator = elevators[id] ?
    id: id
    name: name ? 'John Do'
    tick: 0
    going: []
    inside: []
  elevator.reset = true
  elevator.floor = 0
  elevator.waiting = []
  elevator.going = []
  elevator.inside = []
  elevators[id] = elevator

exports.score = (id) ->
  score(id)

exports.scores = () ->
  {name: elevator.name, score: score(id)} for id, elevator of elevators

exports.get = (id) ->
  elevator = elevators[id]
  throw new exports.Uninitialized(id) unless elevator?.reset

  elevator.just_called_get = true
  tick elevator

exports.put = (id, command) ->
  elevator = elevators[id]
  throw new exports.Uninitialized(id) unless elevator?.reset

  tick elevator unless elevator.just_called_get
  elevator.just_called_get = false

  switch command
    when 'UP'    then up elevator
    when 'DOWN'  then down elevator
    when 'OPEN'  then open elevator
    when 'CLOSE' then close elevator
    else throw new exports.UnknownCommand(elevator)

up = (elevator) ->
  throw new exports.DoorsOpenMove(elevator) if elevator.open
  throw new exports.NoSuchFloor(elevator) if elevator.floor == building.max
  elevator.floor += 1

down = (elevator) ->
  throw new exports.DoorsOpenMove(elevator) if elevator.open
  throw new exports.NoSuchFloor(elevator) if elevator.floor == building.min
  elevator.floor -= 1

open = (elevator) ->
  elevator.open = true

close = (elevator) ->
  elevator.open = false

tick = (elevator) ->
  has_to_go_to_floor = (has_to_go_to_floors elevator)[0]
  if has_to_go_to_floor
    go elevator, has_to_go_to_floor
  else if elevator.open and elevator.inside[elevator.floor] > 0
    exit elevator
  else if elevator.open and waiting elevator, elevator.floor
    enter elevator
  else
    next_step elevator

go = (elevator, floor) ->
  elevator.going.push floor

  event: "go"
  floor: floor

exit = (elevator) ->
  people = elevator.inside[elevator.floor]
  elevator.inside[elevator.floor] = 0
  score elevator.id, people * 10

  event: "exit"
  people: people

enter = (elevator) ->
  for waiter in elevator.waiting[elevator.floor]
    elevator.inside[waiter.dest] = (elevator.inside[waiter.dest] ? 0) + 1

  people = elevator.waiting[elevator.floor].length
  elevator.waiting[elevator.floor] = []

  event: "enter"
  people: people

next_step = (elevator) ->
  step = scenario[elevator.tick % scenario.length]
  elevator.tick += 1

  if step
    elevator.waiting[step.from] ?= []
    for dest in step.to
      elevator.waiting[step.from].push {dest: dest, tick: tick}

    event: "call"
    floor: step.from
  else
    event: "nothing"

has_to_go_to_floors = (elevator) ->
  floor for people, floor in elevator.inside when people > 0 and floor not in elevator.going

waiting = (elevator, floor) ->
  elevator.waiting[elevator.floor] and
  elevator.waiting[elevator.floor].length > 0

score = (id, increment) ->
  current = scores[id] ? 0
  current += increment if increment
  scores[id] = current
  current


exports.Uninitialized  = (id) ->
  score id, -100
exports.DoorsOpenMove  = (elevator) ->
  destroy elevator
exports.UnknownCommand = (elevator) ->
  destroy elevator
exports.NoSuchFloor = (elevator) ->
  destroy elevator

destroy = (elevator) ->
  score elevator.id, -100
  elevator.reset = false
