module.exports.schema = (db, models, next)->
#  db.use paging
#  db.use transaction

  ## Alarm ���� ���̺�
  models.alarm = db.define "alarm",
    id : Number
    date :
      type : 'date'
      time : true
  ## Deice ���� ���̺�
  models.device = db.define 'device',
    id : Number
    gateway : Number
    uuid : String


  ## ����Ʈ���� ���� ���̺�
  models.gateway = db.define "gateway",
    id : Number
    name : String
    identifier : String
    online : Boolean


  global.DB = models

  db.sync()

  next()
