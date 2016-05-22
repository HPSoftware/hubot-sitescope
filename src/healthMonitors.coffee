###
Copyright 2016 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
Software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License. 
###


functions = require('./functions')
module.exports = (robot) ->
  #   get all monitors status for target or tag
  robot.respond /health of (.*) on (.*)/i, (msg) ->
    getHealthMonitorsForTarget robot,msg

########################################################################################
#  get Health Monitors For Target
########################################################################################

getHealthMonitorsForTarget = (robot,msg) ->
  reporter = msg.message.user.name
  target = msg.match[1].trim()
  target = target.replace("<", "");
  target = target.replace(">", "");
  sis = msg.match[2].trim()
  tempObj = functions.getSisConfigurationObject sis
  if tempObj
    sisUrl = tempObj['url']
    sisAuthorization = tempObj['Authorization']
    if target is 'target'
      targetQuery = "&target_display_name=#{target}"
    else
      targetQuery = "&tag=#{target}"
    queryParam = "entity_type=monitor&identifier=#{reporter}&get_full_data=true#{targetQuery}"
    url = "#{sisUrl}/monitors?#{queryParam}"
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

