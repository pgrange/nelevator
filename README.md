# Nelevator

An http elevator engine, just for fun.

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

Not so fun to do while no one has started to play yet but from time to time you may want to look at the scores of the registered elevators. Getting the `scores` resource will give you this :

```
GET /scores
```

For instance:

```bash
$> curl localhost:12045/scores
```

Or for a _live_ scoring table:

```bash
$> watch -d curl -s localhost:12045/scores
```

## Register a new elevator

Before playing with your elevator, you have to register it. To do that, choose a _secret_ id for your elevator. You will use this _id_ later to identify your elevator to the engine. Do not share this id too much... Also choose a name for your elevator. The name will be displayed in scores.

When you made your choice put it in the engine:

```
PUT /<elevator id>/name/<elevator name>
```

For instance :

```bash
$> curl -X PUT localhost:12045/secret123/master_elevator
```

## Get events for your elevator

Events are occuring in the building. People are calling for the elevator to come at some floors, people are entering and exiting the elevator or asking to go to a given floor.

To get this events and act accordingly, you have to request it from the engine for your elevator:

```
GET /<elevator id>
```

For instance :

```bash
$> curl localhost:12045/secret123
```

The next event for elevator is returned as a JSON object. Event can be one of `call`, `go`, `enter`, `exit` or `nothing`. For instance:

* elevator called at second floor : `{ "event": "call", "floor": 2 }`

* elevator asked to go to third floor : `{ "event": "go", "floor": 3 }`

* 2 people have entered the elevator : `{ "event": "enter", "people": 2 }`

* 1 people has exited the elevator : `{ "event": "exit", "people": 1 }`

* nothing happened : `{ "event": "nothing" }`
    
This request will fail with `HTTP/403` if you try to get next event for a crashed or unitialized elevator. See how to register a new elevator or reset a crashed one for more information.

## Put order for your elevator

Now that you know what is happening in the building, you can put order for your elevator to satisfy as many people as you can. Possible orders are `UP`, `DOWN`, `OPEN` and `CLOSE`:

```
PUT /<elevator id>/<command>
```

For instance :

```bash
$> curl -X PUT localhost:12045/secret123/UP
```

WARNING ! An elevator should ask for next event before sending its next command. Otherwise, it may loose some events. For instance this sequence :
```
GET /12043
PUT /12043/UP
PUT /12043/UP
```

Is equivalent to this sequence but ignoring second GET and may be loosing the information that someone called the elevator somwhere :
```
GET /12043
PUT /12043/UP
GET /12043
PUT /12043/UP
```

This request will fail with HTTP/403 if you try to make an illegal move. For instance if you try to move your elevator while its doors are open or if you go through the ceiling or through the ground of the building. If you crash your elevator in such a way, you will have to reset it before being able to put more orders. See how to reset a crashed one for more information.

## Reset your elevator after a crash

After your elevator crashed, you are not allowed to put orders or get events until you have reset your elevator. Trying to put orders or getting events on a crashed or unexisting elevator will make you loose points (yes, a not yet existing elevator can loose points).

To reset an elevator, just put on its resource :

```
PUT /<elevator id>
```

For instance :

```bash
$> curl -X PUT localhost:12045/secret123
```

## Scores

You will gain points every time someone reaches its destination floor (and exit from the elevator...).

You will loose points every time your elevator crashes or every time you try to get events or put orders on a crashed or not yet existing elevator.

