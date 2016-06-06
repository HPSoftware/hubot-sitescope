functions = require('./functions')

module.exports = (robot) ->

  #   Run monitor or group
  robot.respond /run monitor (.*) on (.*)/i, (msg) ->
    runMonitorOrGroup   robot, msg , "Monitor" ,"fullPathToMonitor", "monitor"

  robot.respond /run group (.*) on (.*)/i, (msg) ->
    runMonitorOrGroup   robot, msg , "Group" ,"fullPathToGroup" ,"group"

########################################################################################
#  run monitor or group
########################################################################################

runMonitorOrGroup = (robot, msg ,entityType,fullPathKey,api) ->
  jsonData = {}
  reporter = msg.message.user.name
  jsonData['identifier'] = reporter;
  full_pathArr = msg.match[1].trim().split("/")
  entityName = full_pathArr[full_pathArr.length - 1]
  full_path = full_pathArr.join("_sis_path_delimiter_")
  sis = msg.match[2].trim()
  tempObj = functions.getSisConfigurationObject sis
  if tempObj
    sisUrl = tempObj['url']
    sisAuthorization = tempObj['Authorization']
    formData ="#{fullPathKey}=#{full_path}&identifier=#{reporter}"
    url = "#{sisUrl}/monitors/#{api}/run?#{formData}"
    functions.runMonitor robot,msg,sisAuthorization,url,msg.match[1].trim().toString(),entityType.toString(),entityName.toString()
  else
    robot.logger.debug "We can't find any configuration Sitescope"
    msg.send "We can't find any configuration Sitescope"


