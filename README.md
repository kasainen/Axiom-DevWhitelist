# Axiom Dev Whitelist (FiveM)

Concise, server-only whitelist for developer servers. Uses oxmysql to check Discord IDs written by the "Axiom B1" Discord Bot.

## Requirements
- oxmysql (must start before this resource)
- Axiom B1 Discord Bot configured to write whitelist rows (Unreleased)

## Install
Add to `server.cfg`:
```
ensure oxmysql
ensure dev_whitelist
# optional table override used by this resource (the bot must match)
# set devwl_table "fivem_dev_whitelist"
```

## Configure
`dev_whitelist/config.lua`:
- `tableName` from convar `devwl_table` (default `fivem_dev_whitelist`)
- `cacheTtlSeconds` (default 60)
- `messages` for missing Discord, not whitelisted, and generic errors

## Command
- `refreshdevwl` (console/ACE) clears the cache and logs "Dev whitelist cache cleared".
