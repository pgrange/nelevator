# Nelevator

An http elevator enging, just for fun.

Build your own elevator and connect to the engine to start gaining and loosing points.

## Start your engine

You will need nodejs and gnu make. Then git clone the project and run the elevator :

```bash
$> git clone git@github.com:pgrange/nelevator.git
$> cd nelevator
$> make run
...
connect to http://localhost:12045
```
Engine is ready for new elevators to connect to it at http://localhost:12045

## Take a look at scores

Not so fun to do while noone has started to play yet but from time to time you may want to look at the scores of the registered elevators. The ''scores'' resource will give you this :

```
GET /scores
```

For instance :

```bash
$> curl localhost:12045/scores
```

## REST API

 GET /<id>
 -> return next event for elevator <id> as a JSON object.
    Return HTTP/400 if elevator is not in a state to
    receive new event. For instance if it has not made
    any move between two GET requests.

    Event can be one of call, go, enter, exit or nothing.
    * elevator called at second floor :
    { "event": "call",
      "floor": 2 }

    * elevator asked to go to third floor :
    { "event": "go",
      "floor": 3 }

    * 2 people have entered the elevator :
    { "event": "enter",
      "people": 2 }

    * 1 people have exited the elevator :
    { "event": "exit",
      "people": 1 }

    * nothing happened :
    { "event": "nothing" }

 PUT /<id>
 -> Creates or reset an elevator. This will result
    in elevator <id> being a brand new elevator
    places at floor 0 with doors closed.

 PUT /<id>/<command>
 -> receive next command of the elevator <id>.
    Return HTTP/200 for valid command.
    Return HTTP/400 for invalid command, for instance if
    elevator is asking to go higher than the last floor.

    Command can be one of UP, DOWN, OPEN, CLOSE

 WARNING ! An elevator should ask for next event before
 sending a command every time. Or it may loose some events.
 This sequence :
 GET /12043
 PUT /12043/UP
 PUT /12043/UP
 Is equivalent to this sequence but ignoring second GET :
 GET /12043
 PUT /12043/UP
 GET /12043
 PUT /12043/UP
