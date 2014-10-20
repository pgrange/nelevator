require('source-map-support').install()

express = require('express')

engine = require('./engine')
engine.scenario [
  {from: 1, to: [2]}
]

app = express()
app.use express.bodyParser()
#app.use express.logger()

app.put '/:elevator', (req, res) ->
  elevator = req.param('elevator')
  res.send(engine.reset elevator)

app.put '/:elevator/name/:name', (req, res) ->
  elevator = req.param('elevator')
  name = req.param('name')
  console.log req.ip + ": " + name + " subscription"
  res.send(engine.reset elevator, name)


app.get '/scores', (req, res) ->
  res.send engine.scores()

app.get '/:elevator', (req, res) ->
  try 
    elevator = req.param('elevator')
    current = engine.get elevator
    res.send(current)
    console.log JSON.stringify engine.elevators
    console.log "scores" + JSON.stringify engine.scores()
  catch error
    res.status(403)
    res.type('txt').send('Forbidden')

app.put '/:elevator/:command', (req, res) ->
  try
    elevator = req.param('elevator')
    command = req.param('command')
    engine.put elevator, command
    res.send(200)
    console.log JSON.stringify engine.elevators
  catch error
    res.status(400)
    res.type('txt').send('Bad Request')

app.listen 12045
console.log 'connect to http://localhost:12045'
