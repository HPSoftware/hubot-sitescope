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


