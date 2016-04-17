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

attachmentsResult = []

module.exports = (robot) ->
    LoadSitescopeInstencesConfiguration robot
    LoadSitescopeSupportCommands robot
    
#   Add acknowledgement to entity.
    robot.hear /ack to (.*) for (.*) enable (.*)/i, (msg) ->
        addAck robot,msg,true

    robot.hear /ack to (.*) for (.*) disable (.*)/i, (msg) ->
        addAck robot,msg,false
        
#   Enable or disable entity , monitor or group
    robot.respond /enable monitor (.*) on (.*)/i, (msg) ->
        setEnableDisableStatus robot,msg,"monitor",true
     robot.respond /disable monitor (.*) on (.*)/i, (msg) ->
        setEnableDisableStatus robot,msg,"monitor",false
    robot.respond /enable group (.*) on (.*)/i, (msg) ->
        setEnableDisableStatus robot,msg,"group",true
     robot.respond /disable group (.*) on (.*)/i, (msg) ->
        setEnableDisableStatus robot,msg,"group",false
    
#   Find monitor, group , tag or all on SiteScope
    robot.respond /find monitor (.*) on (.*)/i, (msg) ->
        robot.logger.debug "We are in find"
        findEntity robot,msg,"monitor"
        
    robot.respond /find group (.*) on (.*)/i, (msg) ->
        findEntity robot,msg,"group"
        
    robot.respond /find tag (.*) on (.*)/i, (msg) ->
        findEntity robot,msg,"tag"
        
    robot.respond /find all (.*) on (.*)/i, (msg) ->
        findEntity robot,msg,"all"

#   Get monitors list (recursive) in group
    robot.respond /get monitors in group (.*) on (.*)/i, (msg) ->
        getMonitorsInGroup robot,msg,false
    
    robot.respond /get monitors recursive in group (.*) on (.*)/i, (msg) ->
        getMonitorsInGroup robot,msg,true
        
#   get all monitors status for target or tag
    robot.respond /health of (.*) on (.*)/i, (msg) ->
        getHealthMonitorsForTarget robot,msg

#   Show or reload SiteScope instances configuration file
    robot.respond /load SiteScope config file/i, (msg) ->
        loadSiteScopeConfigFile robot,msg
    robot.respond /show SiteScope config file/i, (msg) ->
        showSiteScopeConfigFile robot,msg
        
#   Run monitor or group
    robot.respond /run monitor (.*) on (.*)/i, (msg) ->
        runMonitorOrGroup   robot, msg , "Monitor" ,"fullPathToMonitor", "monitor"
    
    robot.respond /run group (.*) on (.*)/i, (msg) ->
        runMonitorOrGroup   robot, msg , "Group" ,"fullPathToGroup" ,"group"
        
    robot.respond /get entities for (.*)/i, (msg) ->
        getEntities robot,msg        

#   Generates SiteScope support comands.
    robot.respond /SiteScope help/i, (msg) ->
        getSiteScopeHelpSupport robot,msg 


########################################################################################
#  get Query Param from json object
########################################################################################

getQueryParam = (jsonDat) ->
  queryParams = ''
  for key of jsonDat
    queryParams = queryParams + key + '=' + jsonDat[key] + '&'
  queryParams

########################################################################################
#  Add acknowledgement
########################################################################################

addAck = (robot,msg,enable) ->
  
  jsonData = {}
  reporter = msg.message.user.name
  jsonData['identifier'] = reporter;
  sis = msg.match[1].trim()
  
  entity = msg.match[2].trim().replace("/","_sis_path_delimiter_")
  jsonData['fullPathToEntity'] = entity;
  jsonData['associatedAlertsDisableStartTime'] = 0;
  if enable
    jsonData['associatedAlertsDisableEndTime'] = 0;
  else
    jsonData['associatedAlertsDisableEndTime'] = 60 * 60 * 1000 ;# 1 hour in milliseconds units
  jsonData['acknowledgeComment'] = msg.match[3].trim();
  
  tempObj = getSisConfigurationObject sis
  if tempObj
    sisUrl = tempObj['url']
    sisAuthorization = tempObj['Authorization']
    formData = getQueryParam jsonData
    url = "#{sisUrl}/monitors/monitor/acknowledgement?#{formData}"
    addAcknowledgement robot,msg,sisAuthorization,url
  else
    robot.logger.debug "We can't find any configuration Sitescope"
    msg.send "We can't find any configuration Sitescope"

########################################################################################
#  set Enable Disable Status
########################################################################################
    
setEnableDisableStatus = (robot,msg,type,enable) ->    
  reporter = msg.message.user.name
  full_pathArr = msg.match[1].trim().split("/")
  entityName = full_pathArr[full_pathArr.length - 1]
  full_path = full_pathArr.join("_sis_path_delimiter_")
  sis = msg.match[2].trim()
  tempObj = getSisConfigurationObject sis
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

########################################################################################
#  find Entity
########################################################################################
findEntity = (robot,msg,entity_type) ->    
  reporter = msg.message.user.name
  sis = msg.match[2].trim()
  monitorName = msg.match[1].trim()
  tempObj = getSisConfigurationObject sis
  if tempObj
    sisUrl = tempObj['url']
    sisAuthorization = tempObj['Authorization']
    
    switch entity_type
        when "tag" then additional_query = "&#{monitorName}=#{monitorName}&maxNumOfResults=20"
        when "monitor" then additional_query = "&get_full_data=true&entity_type=#{entity_type}&name=#{monitorName}"
        when "group" then additional_query = "&get_full_data=true&entity_type=#{entity_type}&name=#{monitorName}"
        when "all" then additional_query = "&get_full_data=true&name=#{monitorName}"
    queryParam = "identifier=#{reporter}#{additional_query}"
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

      if error
        robot.logger.error error
        msg.send "There was a problem with Sitescope"
        return robot.emit 'error', error, msg

      try
        entities = JSON.parse(body)
        entitiesResult = []
        for entity of entities
          entityPath = entity.split("_sis_path_delimiter_")
          entityName = entityPath.pop()
          if entityPath.length == 0
            entityPath.push("SiteScope root")
          entityPath = entityPath.join("/")
          val = "Name: #{entityName}  Path: #{entityPath}"
          entityVal = 
            value:val
          entitiesResult.push entityVal
        if entity_type is "all"
          s="";
        else
          s="s"
        titleStr = "#{entity_type}#{s} list"
        attachmentsResult =
            color:'#0000FF'
            title:titleStr
            fields: entitiesResult
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
#  get Monitors In Group
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
      catch err
        robot.logger.error err
        return robot.emit 'error', err, msg
  else
    robot.logger.debug "We can't find any configuration Sitescope"
    msg.send "We can't find any configuration Sitescope"


########################################################################################
#  get All Monitors In Group
########################################################################################

getAllMonitorsInGroup = (robot,groupPath,monitors,monitorsList) ->
    for monitor of monitors
        val = "Monitor name:#{monitor}  Path:  #{groupPath}"
        monitorName = 
            value:val
        monitorsList.push monitorName

      
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
#  get Health Monitors For Target 
########################################################################################

getHealthMonitorsForTarget = (robot,msg) ->
    reporter = msg.message.user.name
    target = msg.match[1].trim()
    target = target.replace("<", "");
    target = target.replace(">", "");
    sis = msg.match[2].trim()
    tempObj = getSisConfigurationObject sis
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
            runMonitor robot,msg,sisAuthorization,url,full_path.toString(),entityType.toString(),entityName.toString()
          if !found
            robot.logger.debug " monitor not found"
            msg.send "monitor not found"
        catch err
          robot.logger.error err
          return robot.emit 'error', err, msg
    else
      robot.logger.debug "We can't find any configuration Sitescope"
      msg.send "We can't find any configuration Sitescope"

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
    tempObj = getSisConfigurationObject sis
    if tempObj
      sisUrl = tempObj['url']
      sisAuthorization = tempObj['Authorization']
      formData ="#{fullPathKey}=#{full_path}&identifier=#{reporter}"
      url = "#{sisUrl}/monitors/#{api}/run?#{formData}"
      runMonitor robot,msg,sisAuthorization,url,msg.match[1].trim().toString(),entityType.toString(),entityName.toString()
    else
      robot.logger.debug "We can't find any configuration Sitescope"
      msg.send "We can't find any configuration Sitescope"



########################################################################################
#  run monitor function
########################################################################################

runMonitor = (robot,msg,sisAuthorization,url,fullPath,entityType,entityName) ->
    msg.http(url)
    .headers( 'Content-type': 'application/x-www-form-urlencoded','Authorization': sisAuthorization)
    .post() (error, res, body) ->
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
      runningResult = JSON.parse(body)
      
      attachmentsResults = []
      attachmentsResults.push createMonitorGroupRunningResult runningResult,fullPath,entityType,entityName                
      msgData =
          channel: msg.message.room
          attachments:attachmentsResults
  
      robot.emit 'slack.attachment', msgData 

########################################################################################
#  Add Acknowledgement function
########################################################################################

addAcknowledgement = (robot,msg,sisAuthorization,url) ->
    msg.http(url)
    .headers( 'Content-type': 'application/x-www-form-urlencoded','Authorization': sisAuthorization)
    .post() (error, res, body) ->
      statusOK = 204
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
      msg.send "Acknowledgement was added successfully"

########################################################################################
#  Get SisConfiguration Object function
########################################################################################

getSisConfigurationObject = (sis) ->
    allSisObj = JSON.parse(process.env.SIS_CONFIGURATION)
    tempObj = null
    for key of allSisObj
      regexp = new RegExp(sis,"i")
      if key.match(regexp)
        tempObj = allSisObj[key]
        break
    tempObj
    
########################################################################################
#  createResultMessage function
########################################################################################

createResultMessage = (msg,colorMsg,fallbackMsg,titleMsg,valueMsg,shortMsg) ->
    msgData =
                channel: msg.message.room
                attachments:[
                      color:colorMsg
                      fallback: fallbackMsg
                      title:"SiteScope Alert"
                      fields: [
                              title: titleMsg
                              value:valueMsg
                              short:shortMsg
                              ]
                            ]
    

########################################################################################
#  Create Monitor or Group Running Result function
########################################################################################

createMonitorGroupRunningResult = exports.createMonitorGroupRunningResult = (runningResult,fullPath,entityType,entityName) ->

    runMonitorStatusSnapshot_lastRun = runningResult['runMonitorStatusSnapshot_lastRun']
    runMonitorStatusSnapshot_status = runningResult['runMonitorStatusSnapshot_status']
    runMonitorStatusSnapshot_statusMessage = runningResult['runMonitorStatusSnapshot_statusMessage']
    datetime = new Date(Number(runMonitorStatusSnapshot_lastRun))
    dateString = datetime.toGMTString()
    resultArr = runMonitorStatusSnapshot_statusMessage.split(',')
    resultArr.unshift('Results:')
    type = entityType
    if(entityType!="Group" and entityType!="Monitor")
      type = entityType + ' Monitor'
    switch runMonitorStatusSnapshot_status
        when "ERROR" then colorStatus = 'danger'
        when "WARNING" then colorStatus = 'warning'
        when "GOOD" then colorStatus = 'good'
        when "DISABLE" then colorStatus = '#D3D3D3'
        else colorStatus = '#0000FF'

    attachments = 
              color:colorStatus
              title:type + ' : ' + fullPath.split("_sis_path_delimiter_").join("/")
              fields: [
                      title: "Details:"
                      value:"Name: #{entityName}\nStatus: #{runMonitorStatusSnapshot_status}\nLast Running: #{dateString}\n#{resultArr.join('\n')}"
                      short:false
                      ]

########################################################################################
#  Create Monitor or Group Result function
########################################################################################

createMonitorGroupSnapshotResult = (tempObj) ->

    configuration_snapshot = tempObj['configuration_snapshot']
    runtime_snapshot = tempObj['runtime_snapshot']
    fullPath = configuration_snapshot['full_path']
    monitorName = configuration_snapshot['name']
    update = new Date(Number(configuration_snapshot['updated_date']))
    dateString = update.toGMTString()
    resultArr = runtime_snapshot['summary'].split(',')
    status =  runtime_snapshot['status']
    resultArr.unshift('Results:')
    entityType = 'Group'
    if(configuration_snapshot['type']!=entityType)
      entityType = configuration_snapshot['type'] + ' Monitor'
    switch status
        when "Error" then colorStatus = 'danger'
        when "Warning" then colorStatus = 'warning'
        when "Good" then colorStatus = 'good'
        when "Disabled" then colorStatus = '#D3D3D3'
        else colorStatus = '#0000FF'

    attachments = 
              color:colorStatus
              title:entityType + ' : ' + fullPath.split("_sis_path_delimiter_").join("/")
              fields: [
                      title: "Details:"
                      value:"Name: #{monitorName}\nStatus: #{status}\nLast Monitor Run: #{dateString}\n#{resultArr.join('\n')}"
                      short:false
                      ]

########################################################################################
#  Load Sitescope instences configuration
########################################################################################

LoadSitescopeInstencesConfiguration = (robot) ->
  fileupload.get 'sitescope-instances.config', (error, data) ->
    if error
      robot.logger.error error
      return robot.emit 'error', error, msg
    process.env.SIS_CONFIGURATION = data

########################################################################################
#  get entities 
########################################################################################

getEntities = (robot,msg) ->
    reporter = msg.message.user.name
    sis = msg.match[1].trim()
    tempObj = getSisConfigurationObject sis
    if tempObj
      sisUrl = tempObj['url']
      sisAuthorization = tempObj['Authorization']
      queryParam = "identifier=#{reporter}&get_full_data=true"
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
          attachmentsResults = []
          for key of obj
            tempObj = obj[key]
            attachmentsResults.push createMonitorGroupSnapshotResult tempObj                
          msgData =
                    channel: msg.message.room
                    attachments:attachmentsResults
      
          robot.emit 'slack.attachment', msgData 
        catch err
          robot.logger.error err
          return robot.emit 'error', err, msg
    else
      robot.logger.debug "We can't find any configuration Sitescope"
      msg.send "We can't find any configuration Sitescope"
    
########################################################################################
#  get entities 
########################################################################################

getSiteScopeHelpSupport = (robot,msg) -> 
    msgData =
      channel: msg.message.room
      text:'*Support SiteScope Commands*'
      attachments:attachmentsResult
    robot.emit 'slack.attachment', msgData 

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
