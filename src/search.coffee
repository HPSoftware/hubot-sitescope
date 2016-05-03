functions = require('./functions')
defaultSis = "SisAppPulse"
module.exports = (robot) ->
  #   search monitor, group , tag or all on SiteScope
  robot.respond /sitescope search monitors for (.*)/i, (msg) ->
    robot.logger.debug "We searching for monitors"
    searchEntity robot,msg,"monitor"

  robot.respond /sitescope search group for (.*)/i, (msg) ->
    searchEntity robot,msg,"group"

  robot.respond /sitescope search tag for (.*)/i, (msg) ->
    searchEntity robot,msg,"tag"

  robot.respond /sitescope search all for (.*)/i, (msg) ->
    searchEntity robot,msg,"all"

  robot.respond /sitescope get entities/i, (msg) ->
    getEntities robot,msg

########################################################################################
#  Search Entity
########################################################################################

searchEntity = (robot,msg,entity_type) ->
  reporter = msg.message.user.name
  sis = msg.match[2]
  if sis == undefined
    sis = defaultSis
  else
    sis = sis.trim()

  monitorName = msg.match[1].trim()
  tempObj = functions.getSisConfigurationObject sis
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
          entityPath = entityPath.join("/")
          entityVal =
            value:entityPath
          entitiesResult.push entityVal
        if entity_type is "all"
          s="";
        else
          s="s"
        titleStr = "Sitescope #{entity_type}#{s} for '#{monitorName}'"
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
#  get entities
########################################################################################

getEntities = (robot,msg) ->
  reporter = msg.message.user.name
  sis = msg.match[2]
  if sis == undefined
    sis = defaultSis
  else
    sis = sis.trim()

  robot.logger.debug "sis = #{sis}"
  tempObj = functions.getSisConfigurationObject sis
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
          attachmentsResults.push functions.createMonitorGroupSnapshotResult tempObj
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
