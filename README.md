# hubot-sitescope

A hubot script for SiteScope ChatOps integration

## Installation

In hubot project repo, run:

`npm install hubot-sitescope --save`

Then add **hubot-sitescope** to your `external-scripts.json`:

```json
[
  "hubot-sitescope"
]
```
## Config
User put configuration in a config file, see example https://github.hpe.com/ChatOps/hubot-integrations/blob/master/hubot-sitescope/src/sitescope-setting.config
```json
{
    "variables":{
      "default_sis"  :"SisAppPulse"
    },
    "instances":{
        "SisAppPulse": {
                "url": "http://myd-vm22177:8080/SiteScope/api",
                "Authorization": "Basic YWRtaW46YWRtaW4="
         },
        "SisOnAmazon": {
                "url": "http://ec2-52-201-214-26.compute-1.amazonaws.com:8080/SiteScope/api",
                "Authorization": "Basic YWRtaW46YWRtaW4="
         }
    },
    "help_commands":{
        "Show/reload configuration ": {
                "Description": "Show or reload SiteScope instances configuration file",
                "Syntax": "show SiteScope config file\nreload SiteScope config file",
                "Examples":""
         },
		 ...............
        "Search monitor/group": {
                "Description": "Search monitors, group , tag or all",
                "Syntax": "sitescope search [entity type] for [Entity name]",
                "Examples":"sitescope search monitors for mem\nsitescope search group for memMonitors\nsitescope search tag for DockerMonitors\nsitescope search all for Docker"
         },
        "Run monitor/group": {
                "Description": "Run monitor, for monitors in group set group's path",
                "Syntax": "sitescope run monitors [Entity full path]",
                "Examples":"sitescope run monitors memMonitors/mem\nrun monitors in group: sitescope run monitors HPE/M1"
         }
    }
}
```
Use the default_sis parameter for configure the default SiteScope instance.
After changing values Please reload configuration again  

## Commands support

1. Show/reload configuration
```
	Description: Show or reload SiteScope instances configuration file.
	Syntax: show SiteScope config file
			reload SiteScope config file
```  
1. Add acknowledgement
```
	Description:Add acknowledgement to entity.
	Syntax: 	ack to [SiteScope name] for [Entity full path] disable [Comment]
				ack to [SiteScope name] for [Entity full path] enable [Comment]
	Examples:	ack to SisOnAmazon for memMonitors/mem disable I'm on it
				ack to SisOnAmazon for memMonitors/mem enable it's now ok
```  
1. Enable/disable Entity
```
	Description:Enable or disable entity , monitor or group.
	Syntax: 	sitescope [enable | disable] [entity type] [Entity full path]
	Examples:	sitescope enable group HPE/M1\nsitescope disable group HPE/M1
				sitescope enable monitor memMonitors/mem
				sitescope disable monitor memMonitors/mem
```  
1. Get monitors list
```
	Description:Get monitors list (recursive) in group.
	Syntax: 	get monitors in group [Group full path] on [SiteScope name]
				get monitors recursive in group [Group full path] on [SiteScope name]
	Examples:	get monitors in group HPE/M1 on SisOnAmazon
				get monitors recursive in group HPE/M1 on SisOnAmazon
```  
1. Enable/disable Entity
```
	Description:Enable or disable entity , monitor or group.
	Syntax: 	sitescope [enable | disable] [entity type] [Entity full path]
	Examples:	sitescope enable group HPE/M1\nsitescope disable group HPE/M1
				sitescope enable monitor memMonitors/mem
				sitescope disable monitor memMonitors/mem
```  
1. health
```
	Description:get all monitors status for target or tag.
	Syntax: 	health of [Target | Tag] on [SiteScope name]
	Examples:	health of SiteScope Server on SisOnAmazon
				health of DockerTag on SisOnAmazon
```  
1. Search monitor/group
```
	Description:Search monitors, group , tag or all.
	Syntax: 	sitescope search [entity type] for [Entity name]
	Examples:	sitescope search monitors for mem
				sitescope search group for memMonitors
				sitescope search tag for DockerMonitors
				sitescope search all for Docker
```  
1. Run monitor/group
```
	Description:Run monitor, for monitors in group set group's path.
	Syntax: 	sitescope run monitors [Entity full path]
	Examples:	sitescope run monitors memMonitors/mem
				run monitors in group: sitescope run monitors HPE/M1
```  