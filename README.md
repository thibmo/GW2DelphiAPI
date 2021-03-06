# GW2DelphiAPI
Delphi (Object Pascal) wrapper for the GuildWars2 public API v1 and v2

This wrapper is WIP, all help is welcome! :-)

Already implemented:  
* Fetching raw endpoint info
* Fetching open API endpoint info
* Fetching authenticated API endpoint info
* Everything with a checkmark under 'Supported'
* Error handeling

###Feature list:

| Feature                                   | Supported | Planned |  
| :------                                   | :------:  | :------: |  
| `render.guildwars2.com`                   |           | ❓️       |  
| `MumbleLink`                              |           | ❓️       |  
| `/v1/build.json`                          | ❌         |         |  
| `/v1/colors.json`                         | ❌         |         |  
| `/v1/continents.json`                     |           | ✔       |  
| `/v1/event_details.json`                  |           | ✔       |  
| `/v1/event_names.json`                    |           | ❓️       |  
| `/v1/events.json`                         |           | ❓️       |  
| `/v1/files.json`                          |           | ✔       |  
| `/v1/guild_details.json`                  |           | ✔       |  
| `/v1/item_details.json`                   |           | ✔       |  
| `/v1/items.json`                          |           | ✔       |  
| `/v1/map_floor.json`                      |           | ✔       |  
| `/v1/map_names.json`                      |           | ✔       |  
| `/v1/maps.json`                           |           | ✔       |  
| `/v1/recipe_details.json`                 |           | ✔       |  
| `/v1/recipes.json`                        |           | ✔       |  
| `/v1/skin_details.json`                   |           | ✔       |  
| `/v1/skins.json`                          |           | ✔       |  
| `/v1/world_names.json`                    |           | ✔       |  
| `/v1/wvw/match_details.json`              |           | ✔       |  
| `/v1/wvw/matches.json`                    |           | ✔       |  
| `/v1/wvw/objective_names.json`            |           | ✔       |  
|                                           |           |         |  
| `/v2/account`                             | ✔         |         |  
| `/v2/account/achievements`                | ✔         |         |  
| `/v2/account/bank`                        | ✔         |         |  
| `/v2/account/dyes`                        | ✔         |         |  
| `/v2/account/finishers`                   | ✔         |         |  
| `/v2/account/inventory`                   | ✔         |         |  
| `/v2/account/masteries`                   | ✔         |         |  
| `/v2/account/materials`                   | ✔         |         |  
| `/v2/account/minis`                       | ✔         |         |  
| `/v2/account/outfits`                     | ✔         |         |  
| `/v2/account/recipes`                     | ✔         |         |  
| `/v2/account/skins`                       | ✔         |         |  
| `/v2/account/titles`                      | ✔         |         |  
| `/v2/account/wallet`                      | ✔         |         |  
| `/v2/achievements`                        | ✔         |         |  
| `/v2/achievements/categories`             |           | ✔       |  
| `/v2/achievements/daily`                  |           | ✔       |  
| `/v2/achievements/daily/tomorrow`         |           | ✔       |  
| `/v2/achievements/groups`                 |           | ✔       |  
| `/v2/adventures`                          |           | ❓️       |  
| `/v2/adventures/:id/leaderboards`         |           | ❓️       |  
| `/v2/adventures/:id/leaderboards/:board`  |           | ❓️       |  
| `/v2/backstory/answers`                   |           | ✔       |  
| `/v2/backstory/questions`                 |           | ✔       |  
| `/v2/build`                               | ✔         |         |  
| `/v2/characters`                          |           | ✔       |  
| `/v2/characters/:id/backstory`            |           | ✔       |  
| `/v2/characters/:id/core`                 |           | ✔       |  
| `/v2/characters/:id/crafting`             |           | ✔       |  
| `/v2/characters/:id/equipment`            |           | ✔       |  
| `/v2/characters/:id/heropoints`           |           | ✔       |  
| `/v2/characters/:id/inventory`            |           | ✔       |  
| `/v2/characters/:id/recipes`              |           | ✔       |  
| `/v2/characters/:id/specializations`      |           | ✔       |  
| `/v2/characters/:id/training`             |           | ✔       |  
| `/v2/colors`                              | ✔         |         |  
| `/v2/commerce/exchange`                   |           | ✔       |  
| `/v2/commerce/listings`                   |           | ✔       |  
| `/v2/commerce/prices`                     |           | ✔       |  
| `/v2/commerce/transactions`               |           | ✔       |  
| `/v2/continents`                          |           | ✔       |  
| `/v2/currencies`                          | ✔         |         |  
| `/v2/emblem`                              |           | ✔       |  
| `/v2/events`                              |           | ❓️       |  
| `/v2/events-state`                        |           | ❓️       |  
| `/v2/files`                               | ✔         |         |  
| `/v2/finishers`                           |           | ✔       |  
| `/v2/guild/:id`                           |           | ✔       |  
| `/v2/guild/:id/log`                       |           | ✔       |  
| `/v2/guild/:id/members`                   |           | ✔       |  
| `/v2/guild/:id/ranks`                     |           | ✔       |  
| `/v2/guild/:id/stash`                     |           | ✔       |  
| `/v2/guild/:id/teams`                     |           | ✔       |  
| `/v2/guild/:id/treasury`                  |           | ✔       |  
| `/v2/guild/:id/upgrades`                  |           | ✔       |  
| `/v2/guild/permissions`                   |           | ✔       |  
| `/v2/guild/search`                        |           | ✔       |  
| `/v2/guild/upgrades`                      |           | ✔       |  
| `/v2/items`                               |           | ✔       |  
| `/v2/itemstats`                           |           | ✔       |  
| `/v2/legends`                             |           | ✔       |  
| `/v2/maps`                                |           | ✔       |  
| `/v2/masteries`                           |           | ✔       |  
| `/v2/materials`                           |           | ✔       |  
| `/v2/minis`                               | ✔         |         |  
| `/v2/outfits`                             |           | ✔       |  
| `/v2/pets`                                |           | ✔       |  
| `/v2/professions`                         |           | ✔       |  
| `/v2/pvp`                                 |           | ✔       |  
| `/v2/pvp/amulets`                         |           | ✔       |  
| `/v2/pvp/games`                           |           | ✔       |  
| `/v2/pvp/seasons`                         |           | ✔       |  
| `/v2/pvp/seasons/:id/leaderboards`        |           | ❓️       |  
| `/v2/pvp/seasons/:id/leaderboards/:board` |           | ❓️       |  
| `/v2/pvp/standings`                       |           | ✔       |  
| `/v2/pvp/stats`                           |           | ✔       |  
| `/v2/quaggans`                            | ✔         |         |  
| `/v2/recipes`                             |           | ✔       |  
| `/v2/recipes/search`                      |           | ✔       |  
| `/v2/skills`                              |           | ✔       |  
| `/v2/skins`                               |           | ✔       |  
| `/v2/specializations`                     |           | ✔       |  
| `/v2/stories`                             |           | ✔       |  
| `/v2/stories/seasons`                     |           | ✔       |  
| `/v2/titles`                              |           | ✔       |  
| `/v2/tokeninfo`                           | ✔         |         |  
| `/v2/traits`                              |           | ✔       |  
| `/v2/worlds`                              | ✔         |         |  
| `/v2/wvw/abilities`                       |           | ✔       |  
| `/v2/wvw/matches`                         |           | ✔       |  
| `/v2/wvw/objectives`                      |           | ✔       |  
