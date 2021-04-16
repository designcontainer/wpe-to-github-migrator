# WPE to Github Migrator

### Before you start:

It is important that you have both Git Permission to the repo and SSH access to the WPE Server.

[Github CLI](https://cli.github.com/) is also required.

### Required Environment Variables:

| Name              | Type                 | Usage                                                                                                              |
| ----------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `ENV_SITE_LIST`   | Environment Variable | Comma separated list of install to migrate                                                                         |
| `ENV_FOLDER_PATH` | Environment Variable | Insert the name of the path you'd like to pull your sites to. Sites will automatically be deleted after migration. |
| `ENV_GH_USER`     | Environment Variable | Your Github Username.                                                                                              |
| `ENV_GH_TOKEN`    | Environment Variable | Your [Github access token](https://github.com/settings/tokens).                                                    |
| `ENV_WPE_USER`    | Environment Variable | Your [WPE API Username. (uuid)](https://my.wpengine.com/api_access).                                               |
| `ENV_WPE_TOKEN`   | Environment Variable | Your [WPE API Key](https://my.wpengine.com/api_access).                                                            |

### To run script:

`$ sh script.sh`
