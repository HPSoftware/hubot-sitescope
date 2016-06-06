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

supportCommandsResult = []
sitescopeSetting = null;

module.exports = (robot) ->
  LoadSitescopeConfiguration robot,null,null

  #   Show or reload SiteScope instances configuration file
  robot.respond /SiteScope reload config file/i, (msg) ->
    reloadSiteScopeConfigFile robot,msg
  robot.respond /SiteScope show config file/i, (msg) ->
    showSiteScopeConfigFile robot,msg
  #   Generates SiteScope support comands.
  robot.respond /SiteScope help/i, (msg) ->
    getSiteScopeHelpSupport robot,msg

########################################################################################
#  Load Sitescope configuration
########################################################################################

LoadSitescopeConfiguration = (robot,msg,show) ->
  robot.logger.debug "load Sitescope setting  config file"
  fileupload.get 'sitescope-setting.config', (error, data) ->
    if error
      robot.logger.error error
      return robot.emit 'error', error, msg
    sitescopeSetting = JSON.parse(data)
    process.env.SIS_CONFIGURATION = data
    loadSitescopeSupportCommands robot
    if show
      showSiteScopeConfigFile robot,msg

########################################################################################
#  Load Sitescope Support Commands
########################################################################################

loadSitescopeSupportCommands = (robot) ->
  allHelpCommands = sitescopeSetting["help_commands"]
  
  fieldsResult = []
  supportCommandsResult = []
  for key of allHelpCommands
    commandObi = allHelpCommands[key]
    Description = {}
    Description['title'] = "Description :"
    Description['value']=commandObi["Description"]
    fieldsResult.push Description

    Syntax = {}
    Syntax['title'] = "Syntax :"
    Syntax['value']=commandObi["Syntax"]
    fieldsResult.push Syntax

    Examples = {}
    Examples['title'] = "Examples :"
    Examples['value']=commandObi["Examples"]
    fieldsResult.push Examples

    attachment =
      color:'#0000FF'
      fields: fieldsResult
    fieldsResult = []
    supportCommandsResult.push(attachment)

########################################################################################
#  reload SiteScope config file
########################################################################################
reloadSiteScopeConfigFile = (robot,msg) ->
  LoadSitescopeConfiguration robot,msg,true

########################################################################################
#  show SiteScope config file
########################################################################################
showSiteScopeConfigFile = (robot,msg) ->
  fieldsResult = []
  sisInstences = getSiteScopeInstances robot 
  defaultInstance = getDefaultSisInstance robot
  for key of sisInstences
    robot.logger.debug "instane : #{key}"
    keyDefault = ""
    if (defaultInstance == key) 
      keyDefault = "is Default"
    instances =
      value:key + " #{keyDefault}"
    fieldsResult.push instances
  instancesResult =
    color:'#0000FF'
    title:"Sitescope instances"
    fields: fieldsResult
  msgData =
    channel: msg.message.room
    attachments:instancesResult
  robot.emit 'slack.attachment', msgData


########################################################################################
#  get SiteScope Help Support
########################################################################################

getSiteScopeHelpSupport = (robot,msg) ->
  msgData =
    channel: msg.message.room
    text:'*Support SiteScope Commands*'
    attachments:supportCommandsResult
  robot.emit 'slack.attachment', msgData


########################################################################################
#  get default instances
########################################################################################

getDefaultSisInstance = (robot) ->
  if sitescopeSetting != null
    robot.logger.debug "default_sis: \n#{JSON.stringify(sitescopeSetting["variables"]["default_sis"])}"
    sitescopeSetting["variables"]["default_sis"];

########################################################################################
#  get instances
########################################################################################

getSiteScopeInstances = (robot) ->
  if sitescopeSetting != null
    robot.logger.debug "SIS_INSTANCES in getSiteScopeInstances: \n#{JSON.stringify(sitescopeSetting["instances"])}"
    sitescopeSetting["instances"];


