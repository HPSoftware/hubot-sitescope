fileupload = require('fileupload').createFileUpload('./scripts')

attachmentsResult = []

module.exports = (robot) ->
  LoadSitescopeInstencesConfiguration robot
  LoadSitescopeSupportCommands robot

  #   Show or reload SiteScope instances configuration file
  robot.respond /load SiteScope config file/i, (msg) ->
    loadSiteScopeConfigFile robot,msg
  robot.respond /show SiteScope config file/i, (msg) ->
    showSiteScopeConfigFile robot,msg
  #   Generates SiteScope support comands.
  robot.respond /SiteScope help/i, (msg) ->
    getSiteScopeHelpSupport robot,msg

########################################################################################
#  Load Sitescope instences configuration
########################################################################################

LoadSitescopeInstencesConfiguration = (robot) ->
  fileupload.get 'sitescope-instances.config', (error, data) ->
    if error
      robot.logger.error error
      return robot.emit 'error', error, msg
    allSisObj = JSON.parse(data)
    result = "first time - setting Sitescope instances:"
    for key of allSisObj
      result = "#{result}\n#{key}"
    process.env.SIS_CONFIGURATION = data
    robot.logger.debug result

########################################################################################
#  Load Sitescope Support Commands
########################################################################################

LoadSitescopeSupportCommands = (robot) ->
  fileupload.get 'sitescope-commands.help', (error, data) ->
    if error
      robot.logger.error error
      return robot.emit 'error', error, msg
    allHelpCommands = JSON.parse(data)
    fieldsResult = []
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
      attachmentsResult.push(attachment)
    process.env.SIS_HELP_COMMANDS = attachmentsResult


########################################################################################
#  load SiteScope config file
########################################################################################
loadSiteScopeConfigFile = (robot,msg) ->
  fileupload.get 'sitescope-instances.config', (error, data) ->
    if error
      robot.logger.error error
      return robot.emit 'error', error, msg
    allSisObj = JSON.parse(data)
    result = "reload setting Sitescope instances:"
    for key of allSisObj
      result = "#{result}\n#{key}"
    process.env.SIS_CONFIGURATION = data
    msg.send result

########################################################################################
#  show SiteScope config file
########################################################################################
showSiteScopeConfigFile = (robot,msg) ->
  allSisObj = JSON.parse(process.env.SIS_CONFIGURATION)
  fieldsResult = []
  for key of allSisObj
    instances =
      value:key
    fieldsResult.push instances
  attachmentsResult =
    color:'#0000FF'
    title:"Sitescope instances"
    fields: fieldsResult
  msgData =
    channel: msg.message.room
    attachments:attachmentsResult
  robot.emit 'slack.attachment', msgData


########################################################################################
#  get SiteScope Help Support
########################################################################################

getSiteScopeHelpSupport = (robot,msg) ->
  msgData =
    channel: msg.message.room
    text:'*Support SiteScope Commands*'
    attachments:attachmentsResult
  robot.emit 'slack.attachment', msgData
