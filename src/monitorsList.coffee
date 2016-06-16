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
  #   Get monitors list (recursive) in group
  robot.respond /SiteScope get monitors in group (.*)/i, (msg) ->
    getMonitorsInGroup robot,msg,false
  
  robot.respond /SiteScope get monitors recursive in group (.*)/i, (msg) ->
    getMonitorsInGroup robot,msg,true

########################################################################################
#  get Monitors In Group
########################################################################################

getMonitorsInGroup = (robot,msg,recursive) ->
  reporter = msg.message.user.name
  groupPath = msg.match[1].trim()
  full_pathArr = groupPath.split("/")
  full_path = full_pathArr.join("_sis_path_delimiter_")
  tempObj = functions.getSisConfigurationObject msg.match[2]
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
      catch err
        robot.logger.error err
        return robot.emit 'error', err, msg
  else
    robot.logger.debug "We can't find any configuration Sitescope"
    msg.send "We can't find any configuration Sitescope"

########################################################################################
#  create Monitors List
########################################################################################

createMonitorsList = (robot,msg,groupPath,jsonList,monitorsList,recursive) ->
  #check for monitor in this group
  monitors = jsonList['snapshot_monitorSnapshotChildren']
  getAllMonitorsInGroup robot,groupPath,monitors,monitorsList
  if recursive
    groups = jsonList['snapshot_groupSnapshotChildren']
    for group of groups
      currentGroupPath = "#{groupPath}/#{group}"
      createMonitorsList robot,msg,currentGroupPath ,groups[group],monitorsList,recursive

########################################################################################
#  get All Monitors In Group
########################################################################################

getAllMonitorsInGroup = (robot,groupPath,monitors,monitorsList) ->
  for monitor of monitors
    val = "Monitor name:#{monitor}  Path:  #{groupPath}"
    monitorName =
      value:val
    monitorsList.push monitorName
