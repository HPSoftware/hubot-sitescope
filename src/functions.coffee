# private Description:
#   functions list for all sitescope uses.
#
# Dependencies:
#   None
#
#
# Author:
#   pini shlomi

general = require('./general')

########################################################################################
#  run monitor function
########################################################################################

exports.runMonitor = (robot,msg,sisAuthorization,url,fullPath,entityType) ->
  msg.http(url)
  .headers( 'Content-type': 'application/x-www-form-urlencoded','Authorization': sisAuthorization)
  .post() (error, res, body) ->
    statusOK = 200
    if res and res.statusCode != statusOK
      try
        obj = JSON.parse(body )
        attachmentsResults = []
        msgTitle =  'Monitor : ' + "Sitescope/" + fullPath.split("_sis_path_delimiter_").join("/")
        attachmentsResults.push createRunningResult 'danger',msgTitle,obj['message']
        msgData =
          channel: msg.message.room
          attachments:attachmentsResults
        robot.emit 'slack.attachment', msgData

        #robot.logger.error "There was a problem with Sitescope,\nError : #{message}"
        #msg.send "There was a problem with Sitescope,\nError : #{message}"
      catch err
        robot.logger.error "There was a problem with Sitescope, Error : #{err}"
        msg.send "There was a problem with Sitescope"
      return
    runningResult = JSON.parse(body)
    attachmentsResults = []
    attachmentsResults.push createMonitorGroupRunningResult runningResult,fullPath,entityType
    msgData =
      channel: msg.message.room
      attachments:attachmentsResults

    robot.emit 'slack.attachment', msgData


########################################################################################
#  Get SisConfiguration Object function
########################################################################################

exports.getSisConfigurationObject = (sis) ->
  if sis == undefined
    sis = JSON.parse(process.env.SIS_CONFIGURATION)["variables"]["default_sis"]
  else
    sis = sis.trim()
  allSisObj = JSON.parse(process.env.SIS_CONFIGURATION)["instances"]
  tempObj = null
  for key of allSisObj
    regexp = new RegExp(sis,"i")
    if key.match(regexp)
      tempObj = allSisObj[key]
      break
  tempObj

########################################################################################
#  createResultMessage function
########################################################################################

createResultMessage = (msg,colorMsg,fallbackMsg,titleMsg,valueMsg,shortMsg) ->
  msgData =
    channel: msg.message.room
    attachments:[
      color:colorMsg
      fallback: fallbackMsg
      title:"SiteScope Alert"
      fields: [
        title: titleMsg
        value:valueMsg
        short:shortMsg
      ]
    ]


########################################################################################
#  Create Monitor or Group Running Result function
########################################################################################

createMonitorGroupRunningResult = (runningResult,fullPath,entityType) ->

  runMonitorStatusSnapshot_lastRun = runningResult['runMonitorStatusSnapshot_lastRun']
  runMonitorStatusSnapshot_status = runningResult['runMonitorStatusSnapshot_status']
  runMonitorStatusSnapshot_statusMessage = runningResult['runMonitorStatusSnapshot_statusMessage']
  datetime = new Date(Number(runMonitorStatusSnapshot_lastRun))
  dateString = datetime.toGMTString()
  resultArr = runMonitorStatusSnapshot_statusMessage.split(',')
  resultArr.unshift('Results:')
  type = entityType
  if(entityType!="Group" and entityType!="Monitor")
    type = entityType + ' Monitor'
  switch runMonitorStatusSnapshot_status
    when "ERROR" then colorStatus = 'danger'
    when "WARNING" then colorStatus = 'warning'
    when "GOOD" then colorStatus = 'good'
    when "DISABLE" then colorStatus = '#D3D3D3'
    else colorStatus = '#0000FF'
  
  msgTitle = type + ' : ' + "Sitescope/" + fullPath.split("_sis_path_delimiter_").join("/")
  msgValue = "Status: #{runMonitorStatusSnapshot_status}\nLast Running: #{dateString}\n#{resultArr.join('\n')}"
  
  attachments = createRunningResult colorStatus,msgTitle,msgValue

########################################################################################
#  Create Monitor or Group Result function
########################################################################################
createRunningResult = (colorStatus,msgTitle,msgValue) ->
    attachments =
      color:colorStatus
      title:msgTitle
      fields: [
        title: "Details:"
        value:msgValue
        short:false
      ]

########################################################################################
#  Create Monitor or Group Result function
########################################################################################

exports.createMonitorGroupSnapshotResult = (tempObj) ->

  configuration_snapshot = tempObj['configuration_snapshot']
  runtime_snapshot = tempObj['runtime_snapshot']
  fullPath = configuration_snapshot['full_path']
  monitorName = configuration_snapshot['name']
  update = new Date(Number(configuration_snapshot['updated_date']))
  dateString = update.toGMTString()
  resultArr = runtime_snapshot['summary'].split(',')
  status =  runtime_snapshot['status']
  resultArr.unshift('Results:')
  entityType = 'Group'
  if(configuration_snapshot['type']!=entityType)
    entityType = configuration_snapshot['type'] + ' Monitor'
  switch status
    when "Error" then colorStatus = 'danger'
    when "Warning" then colorStatus = 'warning'
    when "Good" then colorStatus = 'good'
    when "Disabled" then colorStatus = '#D3D3D3'
    else colorStatus = '#0000FF'

  attachments =
    color:colorStatus
    title:entityType + ' : ' + fullPath.split("_sis_path_delimiter_").join("/")
    fields: [
      title: "Details:"
      value:"Name: #{monitorName}\nStatus: #{status}\nLast Monitor Run: #{dateString}\n#{resultArr.join('\n')}"
      short:false
    ]


