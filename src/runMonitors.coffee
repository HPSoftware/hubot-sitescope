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
defaultSis = "SisOnAmazon"

module.exports = (robot) ->

  #   Run monitor or group
  robot.respond /sitescope run monitors (.*)/i, (msg) ->
    runMonitors   robot, msg 

########################################################################################
#  run monitors
########################################################################################

runMonitors = (robot, msg ,entityType,fullPathKey,api) ->
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
          # check if it's monitor( not group)
          robot.logger.debug "we got error when we try to get group snapshot with monitor path "
          formData ="fullPathToMonitor=#{full_path}&identifier=#{reporter}"
          url = "#{sisUrl}/monitors/monitor/run?#{formData}"
          functions.runMonitor robot,msg,sisAuthorization,url,groupPath,"Monitor"
        catch err
          robot.logger.error "There was a problem with Sitescope, Error : #{err}"
          msg.send "There was a problem with Sitescope"
        return

      if error
        robot.logger.error error
        msg.send "There was a problem with Sitescope"
        return robot.emit 'error', error, msg

      try
        # success
        obj = JSON.parse(body )
        jsonList = obj[full_path]
        monitorsList = []
        createMonitorsList robot,msg,full_path,jsonList,monitorsList
        for index of monitorsList
          robot.logger.debug "monitorsList monitor #{monitorsList[index]}"
          formData ="fullPathToMonitor=#{monitorsList[index]}&identifier=#{reporter}"
          url = "#{sisUrl}/monitors/monitor/run?#{formData}"
          monitorFullPath = monitorsList[index].split("_sis_path_delimiter_").join("/")
          functions.runMonitor robot,msg,sisAuthorization,url,monitorFullPath,"Monitor"
  else
    robot.logger.debug "We can't find any configuration Sitescope"
    msg.send "We can't find any configuration Sitescope"



########################################################################################
#  create Monitors List
########################################################################################

createMonitorsList = (robot,msg,groupPath,jsonList,monitorsList) ->
  #check for monitor in this group
  monitors = jsonList['snapshot_monitorSnapshotChildren']
  getAllMonitorsInGroup robot,groupPath,monitors,monitorsList
  groups = jsonList['snapshot_groupSnapshotChildren']
  for group of groups
    currentGroupPath = "#{groupPath}_sis_path_delimiter_#{group}"
    createMonitorsList robot,msg,currentGroupPath ,groups[group],monitorsList


########################################################################################
#  get All Monitors In Group
########################################################################################

getAllMonitorsInGroup = (robot,groupPath,monitors,monitorsList) ->
  for monitor of monitors
    monitorsList.push "#{groupPath}_sis_path_delimiter_#{monitor}"
    

