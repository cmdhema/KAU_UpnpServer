module.exports.schema = (db, models, next)->
#  db.use paging
#  db.use transaction

  ## Alarm 관련 테이블
  models.alarm = db.define "alarm",
    id : Number
    date :
      type : 'date'
      time : true
  ## Deice 관련 테이블
  models.device = db.define 'device',
    id : Number
    gateway : Number
    uuid : String


  ## 게이트웨이 관련 테이블
  models.gateway = db.define "gateway",
    id : Number
    name : String
    identifier : String
    online : Boolean


  global.DB = models

  db.sync()

  next()
