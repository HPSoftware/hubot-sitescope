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
  #   Enable or disable entity , monitor or group
  robot.respond /sitescope enable monitor (.*)/i, (msg) ->
    setEnableDisableStatus robot,msg,"monitor",true
  robot.respond /sitescope disable monitor (.*)/i, (msg) ->
    setEnableDisableStatus robot,msg,"monitor",false
  robot.respond /sitescope enable group (.*)/i, (msg) ->
    setEnableDisableStatus robot,msg,"group",true
  robot.respond /sitescope disable group (.*)/i, (msg) ->
    setEnableDisableStatus robot,msg,"group",false

########################################################################################
#  set Enable Disable Status
########################################################################################

setEnableDisableStatus = (robot,msg,type,enable) ->
  reporter = msg.message.user.name
  full_pathArr = msg.match[1].trim().split("/")
  entityName = full_pathArr[full_pathArr.length - 1]
  full_path = full_pathArr.join("_sis_path_delimiter_")
  tempObj = functions.getSisConfigurationObject msg.match[2]
  if tempObj
    sisUrl = tempObj['url']
    sisAuthorization = tempObj['Authorization']
    if type == "monitor"
      path = "fullPathToMonitor=#{full_path}"
    else
      path = "fullPathToGroup=#{full_path}"
    queryParam = "#{path}&enable=#{enable}&identifier=#{reporter}"
    url = "#{sisUrl}/monitors/#{type}/status?#{queryParam}"
    msg.http(url)
    .headers( 'Content-type': 'application/x-www-form-urlencoded','Authorization': sisAuthorization)
    .post() (error, res, body) ->
      statusOK = 204
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
      if enable
        enableStr = 'enable'
      else
        enableStr = 'disable'
      msg.send "#{type} is #{enableStr}"

  else
    robot.logger.debug "We can't find any configuration Sitescope"
    msg.send "We can't find any configuration Sitescope"

