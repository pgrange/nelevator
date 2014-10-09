scenario = []
elevators = {}

exports.elevators = elevators #debug

exports.scenario = (value) ->
  scenario = value

exports.reset = (id) ->
  elevators[id] =
    floor: 0
    next_step: 0
    waiting: []
    going: []
    inside: []

exports.get = (id) ->
  elevator = elevators[id]
  elevator.just_called_get = true
  tick elevator

exports.put = (id, command) ->
  elevator = elevators[id]
  tick elevator unless elevator.just_called_get
  elevator.just_called_get = false

  switch command
    when 'UP'    then up elevator
    when 'OPEN'  then open elevator
    when 'CLOSE' then close elevator

up = (elevator) ->
  elevator.floor += 1

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
  else if elevator.open and elevator.waiting[elevator.floor]
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

  event: "exit"
  people: people

enter = (elevator) ->
  for dest_floor in elevator.waiting[elevator.floor]
    elevator.inside[dest_floor] = (elevator.inside[dest_floor] ? 0) + 1

  people = elevator.waiting[elevator.floor].length
  elevator.waiting[elevator.floor] = []

  event: "enter"
  people: people

next_step = (elevator) ->
  step = scenario[elevator.next_step]
  elevator.next_step = (elevator.next_step + 1) % scenario.length

  if step
    elevator.waiting[step.from] =
      (elevator.waiting[step.from] ? []).concat step.to

    event: "call"
    floor: step.from
  else
    event: "nothing"

has_to_go_to_floors = (elevator) ->
  floor for floor, people in elevator.inside when people > 0 and floor not in elevator.going
