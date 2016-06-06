functions = require('./functions')
module.exports = (robot) ->
  #   get all monitors status for target or tag
  robot.respond /SiteScope health of target (.*)/i, (msg) ->
    getHealthMonitorsForTarget robot,msg,'target'
  robot.respond /SiteScope health of tag (.*)/i, (msg) ->
    getHealthMonitorsForTarget robot,msg,'tag'

########################################################################################
#  get Health Monitors For Target
########################################################################################

getHealthMonitorsForTarget = (robot,msg,value) ->
  reporter = msg.message.user.name
  target = msg.match[1].trim()
  target = target.replace("<", "");
  target = target.replace(">", "");
  tempObj = functions.getSisConfigurationObject msg.match[2]
  if tempObj
    sisUrl = tempObj['url']
    sisAuthorization = tempObj['Authorization']
    if value is 'target'
      targetQuery = "&target_display_name=#{target}"
    else
      targetQuery = "&#{target}=#{target}"
    queryParam = "entity_type=monitor&identifier=#{reporter}&get_full_data=true#{targetQuery}"
    url = "#{sisUrl}/monitors?#{queryParam}"
    #robot.logger.debug "url: #{url}"
    msg.http(url)
    .headers( Authorization: sisAuthorization, Accept: 'application/json')
    .get() (error, res, body) ->
      statusOK = 200
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

      try
        obj = JSON.parse(body )
        #robot.logger.debug "obj: #{JSON.stringify(obj)}" 
        found = false
        for myKey of obj
          tempObj = obj[myKey]
          configuration_snapshot = tempObj['configuration_snapshot']
          found = true
          full_path = configuration_snapshot['full_path']
          entityType = configuration_snapshot['type']
          entityName = configuration_snapshot['name']
          formData ="fullPathToMonitor=#{full_path}&identifier=#{reporter}"
          url = "#{sisUrl}/monitors/monitor/run?#{formData}"
          functions.runMonitor robot,msg,sisAuthorization,url,full_path.toString(),entityType.toString(),entityName.toString()
        if !found
          robot.logger.debug " monitor not found"
          msg.send "monitor not found"
      catch err
        robot.logger.error err
        return robot.emit 'error', err, msg
  else
    robot.logger.debug "We can't find any configuration Sitescope"
    msg.send "We can't find any configuration Sitescope"

