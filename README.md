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
User put configuration in a config file, see  https://github.hpe.com/ChatOps/hubot-integrations/blob/master/hubot-sitescope/src/sitescope-setting.config
```json
{
    "variables":{
      "default_sis"  :"SisOnAmazon"
    },
    "instances":{
        "SiteScope_Instanse_1": {
                "url": "http://[your host]:8080/SiteScope/api",
                "Authorization": "Basic [your base64 encoded auth]"
         },
        "SiteScope_Instanse_X": {
                "url": " http://[your host]:8080/SiteScope/api",
                "Authorization": "Basic [your base64 encoded auth]"
         }
    },
    "help_commands":{
        "Show/reload configuration ": {
                "Description": "Show or reload SiteScope instances configuration file",
                "Syntax": "SiteScope show config file\nSiteScope reload config file",
                "Examples":""
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

Show/reload configuration
```
	Description: Show or reload SiteScope instances configuration file.
	Syntax: SiteScope show config file
			SiteScope reload config file
```  
Add acknowledgement
```
	Description:Add acknowledgement to entity.
	Syntax: 	SiteScope add ack for [Entity full path] disable [Comment]
				SiteScope add ack for [Entity full path] enable [Comment]
	Examples:	SiteScope add ack for memMonitors/mem disable I'm on it
				SiteScope add ack for memMonitors/mem enable it's OK now
```  
Enable/disable Entity
```
	Description:Enable or disable entity , monitor or group.
	Syntax: 	SiteScope [enable | disable] [entity type] [Entity full path]
	Examples:	SiteScope enable group HPE/M1
				SiteScope disable group HPE/M1
				SiteScope enable monitor memMonitors/mem
				SiteScope disable monitor memMonitors/mem
```  
Get monitors list
```
	Description:Get monitors list (recursive) in group.
	Syntax: 	SiteScope get monitors in group [Group full path]
				SiteScope get monitors recursive in group [Group full path]
	Examples:	SiteScope get monitors in group HPE/M1
				SiteScope get monitors recursive in group HPE/M1
```  
health
```
	Description:get all monitors status for target or tag.
	Syntax: 	health of [Target | Tag] on [SiteScope name]
	Examples:	health of SiteScope Server on SisOnAmazon
				health of DockerTag on SisOnAmazon
```  
Search monitor/group
```
	Description:Search monitors, group , tag or all.
	Syntax: 	SiteScope search [entity type] for [Entity name]
	Examples:	SiteScope search monitors for mem
				SiteScope search group for memMonitors
				SiteScope search tag for DockerMonitors
				SiteScope search all for Docker
```  
Run monitor/group
```
	Description:Run monitor, for monitors in group set group's path.
	Syntax: 	SiteScope run monitors [Entity full path]
	Examples:	SiteScope run monitors memMonitors/mem
				run monitors in group: SiteScope run monitors HPE/M1
```  
