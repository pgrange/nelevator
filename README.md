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

## Register a new elevator

Before playing with your elevator, you have to register it. To do that, choose a ''secret'' id for your elevator. You will use this ''id'' later to identify your elevator to the engine. Do not share this id too much... Also choose a name for your elevator. The name will be displayed in scores.

When you made your choice ''put'' it in the engine:

```
PUT /<elevator id>/name/<elevator name>
```

For instance :

```bash
$> curl -X PUT localhost:12045/secret123/master_elevator
```

## Get events for you elevator

Events are occuring in the building. People are calling for the elevator to come at some floors, people are entering and exiting the elevator or asking to go to a given floor.

To get this events and act accordingly, you have to request it from the engine for your elevator:

```
GET /<elevator id>
```

For instance :

```bash
$> curl localhost:12045/secret123
```

The next event for elevator <id> is returned as a JSON object. Event can be one of ''call'', ''go'', ''enter'', ''exit'' or ''nothing''.

For instance:
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
    
 
 This request will fail with HTTP/403 if you try to get next event for a crashed or unitialized elevator. See how to register a new elevator or reset a crashed one for more information.

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
