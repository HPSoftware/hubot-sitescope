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


# Description
#   SiteScope Hubot by slack adapter
#
# Configuration:
#   sitescope-instances.config
#   sitescope-commands.help
#
# Description:
#   SiteScope Hubot by slack adapter
#
# Commands:
#   hubot: sitescope help
#
# Dependencies:
#	None
#
# Author:
#   pini shlomi shlomi@hpe.com

fileupload = require('fileupload').createFileUpload('./scripts')

module.exports = (robot) ->
  robot.respond /get entities for (.*)/i, (msg) ->
    getEntities robot,msg


########################################################################################
#  get Query Param from json object
########################################################################################

getQueryParam = (jsonDat) ->
  queryParams = ''
  for key of jsonDat
    queryParams = queryParams + key + '=' + jsonDat[key] + '&'
  queryParams


########################################################################################
#  run all Monitors In Group and retrive the status
########################################################################################

getMonitorsInGroup = (robot,msg,recursive) ->
  reporter = msg.message.user.name
  sis = msg.match[2].trim()
  groupPath = msg.match[1].trim()
  full_pathArr = groupPath.split("/")
  full_path = full_pathArr.join("_sis_path_delimiter_")
  tempObj = getSisConfigurationObject sis
  if tempObj
    sisUrl = tempObj['url']
    sisAuthorization = tempObj['Authorization']
    queryParam = "identifier=#{reporter}&fullPathsToGroups=#{full_path}"
    url = "#{sisUrl}/admin/groups/config/snapshot?#{queryParam}"
    msg.http(url)
    .headers( Authorization: sisAuthorization, Accept: 'application/json')
    .get() (error, res, body) ->
      statusOK = 200
      if res and res.statusCode != statusOK
        try
          obj = JSON.parse(body )
          message = obj['message']
          #robot.logger.error "There was a problem with Sitescope,\nError : #{message}"
          msg.send "There was a problem with Sitescope,\nError : #{message}"
        catch err
          robot.logger.error "There was a problem with Sitescope, Error : #{err}"
          msg.send "There was a problem with Sitescope"
        return

      if error
        robot.logger.error error
        msg.send "There was a problem with Sitescope"
        return robot.emit 'error', error, msg

      try
        obj = JSON.parse(body )
        jsonList = obj[full_path]
        monitorsList = []
        createMonitorsList robot,msg,groupPath,jsonList,monitorsList,recursive
        attachmentsResult =
          color:'#0000FF'
          title:"Monitors List in #{groupPath} Group"
          fields: monitorsList
        msgData =
          channel: msg.message.room
          attachments:attachmentsResult
        robot.emit 'slack.attachment', msgData
        createMonitorsList robot,msg,groupPath,jsonList,monitorsList,recursive
      catch err
        robot.logger.error err
        return robot.emit 'error', err, msg
  else
    robot.logger.debug "We can't find any configuration Sitescope"
    msg.send "We can't find any configuration Sitescope"





########################################################################################
#  run Monitors in group
########################################################################################

runMonitorsInGroup = (robot,msg,groupPath,jsonList) ->
  #check for monitor in this group
  monitors = jsonList['snapshot_monitorSnapshotChildren']
  getAllMonitorsInGroup robot,groupPath,monitors,monitorsList
  groups = jsonList['snapshot_groupSnapshotChildren']
  for group of groups
    currentGroupPath = "#{groupPath}/#{group}"
    runMonitorsInGroup robot,msg,currentGroupPath ,groups[group]


########################################################################################
#  run Monitors
########################################################################################

runMonitors = (robot,groupPath,monitors) ->
  for monitor of monitors
    full_path = configuration_snapshot['full_path']
    entityType = configuration_snapshot['type']
    entityName = configuration_snapshot['name']
    formData ="fullPathToMonitor=#{full_path}&identifier=#{reporter}"
    url = "#{sisUrl}/monitors/monitor/run?#{formData}"
    runMonitor robot,msg,sisAuthorization,url,full_path.toString(),entityType.toString(),entityName.toString()





