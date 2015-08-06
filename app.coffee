require('source-map-support').install()
express = require('express')
http = require('http')
orm = require('orm')
async = require('async')
favicon = require('static-favicon')
morgan = require('morgan')
path = require('path')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
config = require('./config')
orm = require('orm')
winston = require('winston')
expressWinston = require('express-winston')
engine = require('ejs-locals')

routes = require('./routes/routes.js')

app = express()

console.log(config);
logger = new winston.Logger
  transports: [
    new winston.transports.Console,
    new winston.transports.File({filename: 'somefile.log'})
  ]

expandErrors = (logger)->
  oldLogFunc = logger.log;
  logger.log = ()->
    args = Array.prototype.slice.call(arguments, 0)
    if (args.length >= 2 && args[1] instanceof Error)
      args[1] = args[1].stack
    return oldLogFunc.apply(this, args)
  return logger

logger = expandErrors(logger)

process.on 'uncaughtException', (err)->
  console.log('Caught exception: ' + err)
  logger.warn('Caught exception: ' + err)

global.log = logger;

databaseUrl = process.argv[2] || config.database;

console.log ("DB Path : " + databaseUrl);

app.use orm.express(databaseUrl, define : require('./routes/databaseSchema').schema)

# view engine setup
app.set('views', path.join(__dirname, 'views'))
app.set('view engine', 'ejs')
app.use(express.static(path.join(__dirname, 'public')))
app.use(express.static(path.join(__dirname, 'routes'))) # JPark, to display document images (/develop/img/*.png)

app.use(favicon())
app.use(morgan('dev'))
app.use(bodyParser.json())
app.use(bodyParser.urlencoded())
app.use(cookieParser())
app.engine('ejs', engine)

routes.doRoutes(app)
app.use (req, res, next)->
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE')
  res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type')
  res.setHeader('Access-Control-Allow-Credentials', true)
  next()


#/ catch 404 and forwarding to error handler
app.use (req, res, next)->
  err = new Error('Not Found')
  err.status = 404
  next(err)

#/ error handlers

# development error handler
# will print stacktrace
if (app.get('env') == 'development')
  app.use (err, req, res, next)->
    res.render 'error',
      message: err.message,
      error: err

# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next)->
  res.render 'error',
    message: err.message,
    error: {}


module.exports = app

require('./socket/socketHandler').connect()
