# hubot-sitescope

A hubot script for SiteScope ChatOps integration

## Installation

1.	Generate new Hubot deployment by running `yo hubot` command or use an existing deployment you already have.
2. From the Hubot main direcrtory, run the following command:
`npm install git+https://github.com/HPSoftware/hubot-sitescope.git --save `
  * This command will install hubot-sitescope package on your Hubot.
3. Then add `hubot-sitescope` to your `external-scripts.json` file contains list of packages from npm:
```json
[
  "hubot-sitescope"
]
```
## Config
Bot configuration stored in config file at: src/sitescope-setting.config

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
* To configure the default SiteScope instance edit `default_sis` parameter.
  * This parameter used to select default SiteScope instance that will be used if no specific instance name specified then running bot commands from the chat
* `instances` parameter represent the array of SiteScope instance settings
  * For each set of settings the url parameter is the URL of the SiteScope REST api in following format: `http(s)://[your SiteScope host]:[port]/SiteScope/api`
* `Authorization`` is the authorization required to authenticate against your SiteScope instance in basic authentication format.
  * For more details about basic atuh please check: [Wiki](https://en.wikipedia.org/wiki/Basic_access_authentication)

**Note**: If your bot is running and you make any changes to the configuration values, then you must reload the configuration file for the changes to take effect.

## Commands support

**Show/reload configuration**
```
	Description: Show or reload SiteScope instances configuration file.
	Syntax: SiteScope show config file
			SiteScope reload config file
```  
**Add acknowledgement**
```
	Description:Add acknowledgement to entity.
	Syntax: 	SiteScope add ack for [Entity full path] disable [Comment]
				SiteScope add ack for [Entity full path] enable [Comment]
	Examples:	SiteScope add ack for memMonitors/mem disable I'm on it
				SiteScope add ack for memMonitors/mem enable it's OK now
```  
**Enable/disable Entity**
```
	Description:Enable or disable entity , monitor or group.
	Syntax: 	SiteScope [enable | disable] [entity type] [Entity full path]
	Examples:	SiteScope enable group HPE/M1
				SiteScope disable group HPE/M1
				SiteScope enable monitor memMonitors/mem
				SiteScope disable monitor memMonitors/mem
```  
**Get monitors list**
```
	Description:Get monitors list (recursive) in group.
	Syntax: 	SiteScope get monitors in group [Group full path]
				SiteScope get monitors recursive in group [Group full path]
	Examples:	SiteScope get monitors in group HPE/M1
				SiteScope get monitors recursive in group HPE/M1
```  
**Check health**
```
	Description:get all monitors status for target or tag.
	Syntax: 	health of [Target | Tag] on [SiteScope name]
	Examples:	health of SiteScope Server on SisOnAmazon
				health of DockerTag on SisOnAmazon
```  
**Search monitor/group**
```
	Description:Search monitors, group , tag or all.
	Syntax: 	SiteScope search [entity type] for [Entity name]
	Examples:	SiteScope search monitors for mem
				SiteScope search group for memMonitors
				SiteScope search tag for DockerMonitors
				SiteScope search all for Docker
```  
**Run monitor/group**
```
	Description:Run monitor, for monitors in group set group's path.
	Syntax: 	SiteScope run monitors [Entity full path]
	Examples:	SiteScope run monitors memMonitors/mem
				run monitors in group: SiteScope run monitors HPE/M1
```  
