require('source-map-support').install()

express = require('express')

engine = require('./engine')
engine.scenario [
  {from: 1, to: 2}
]

app = express()
app.use express.bodyParser()
#app.use express.logger()

app.put '/:elevator', (req, res) ->
  elevator = req.param('elevator')
  res.send(engine.reset elevator)

app.get '/:elevator', (req, res) ->
  elevator = req.param('elevator')
  res.send(engine.get elevator)
  console.log JSON.stringify engine.elevators

app.put '/:elevator/:command', (req, res) ->
  elevator = req.param('elevator')
  command = req.param('command')
  res.send(engine.put elevator, command)
  console.log JSON.stringify engine.elevators

app.listen 12045
console.log 'connect to http://localhost:12045'
