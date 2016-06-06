functions = require('./functions')
module.exports = (robot) ->
  #   Add acknowledgement to entity.
  robot.hear /SiteScope add ack for (.*) enable (.*)/i, (msg) ->
    addAck robot,msg,true

  robot.hear /SiteScope add ack for (.*) disable (.*)/i, (msg) ->
    addAck robot,msg,false

########################################################################################
#  Add acknowledgement
########################################################################################

addAck = (robot,msg,enable) ->

  jsonData = {}
  reporter = msg.message.user.name
  jsonData['identifier'] = reporter;
  entity = msg.match[1].trim().replace("/","_sis_path_delimiter_")
  jsonData['fullPathToEntity'] = entity;
  jsonData['associatedAlertsDisableStartTime'] = 0;
  if enable
    jsonData['associatedAlertsDisableEndTime'] = 0;
  else
    jsonData['associatedAlertsDisableEndTime'] = 60 * 60 * 1000 ;# 1 hour in milliseconds units
  jsonData['acknowledgeComment'] = msg.match[2].trim();

  tempObj = functions.getSisConfigurationObject msg.match[3]
  if tempObj
    sisUrl = tempObj['url']
    sisAuthorization = tempObj['Authorization']
    formData = functions.getQueryParam jsonData
    url = "#{sisUrl}/monitors/monitor/acknowledgement?#{formData}"
    addAcknowledgement robot,msg,sisAuthorization,url
  else
    robot.logger.debug "We can't find any configuration Sitescope"
    msg.send "We can't find any configuration Sitescope"

########################################################################################
#  Add Acknowledgement function
########################################################################################

addAcknowledgement = (robot,msg,sisAuthorization,url) ->
  msg.http(url)
  .headers( 'Content-type': 'application/x-www-form-urlencoded','Authorization': sisAuthorization)
  .post() (error, res, body) ->
    statusOK = 204
    if res and res.statusCode != statusOK
      try
        obj = JSON.parse(body )
        message = obj['message']
        robot.logger.error "There was a problem with Sitescope,\nError : #{message}"
        msg.send "There was a problem with Sitescope,\nError : #{message}"
      catch err
        robot.logger.error "There was a problem with Sitescope, Error : #{err}"
        msg.send "There was a problem with Sitescope"
      return
    msg.send "Acknowledgement was added successfully"
    
