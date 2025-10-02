local RESOURCE_NAME = GetCurrentResourceName()

local cache = {}

local function now()
    return os.time()
end

local function cacheGet(key)
    local entry = cache[key]
    if not entry then return nil end
    if entry.expires < now() then
        cache[key] = nil
        return nil
    end
    return entry.allowed
end

local function cacheSet(key, allowed)
    cache[key] = {
        allowed = allowed,
        expires = now() + (Config.cacheTtlSeconds or 60)
    }
end

local function cacheClear()
    cache = {}
end

local function log(fmt, ...)
    print(('[%s] %s'):format(RESOURCE_NAME, fmt:format(...)))
end

local function getDiscordId(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'discord:' then
            return identifier:sub(9)
        end
    end
    return nil
end

local function ensureOxmysql()
    local state = GetResourceState('oxmysql')
    if state ~= 'started' then
        print(('^1[%s] FATAL: oxmysql is not started (state=%s). Start oxmysql before this resource.^7'):format(RESOURCE_NAME, tostring(state)))
        StopResource(RESOURCE_NAME)
        return false
    end
    return true
end

local function isWhitelisted(discordId)
    if not discordId or discordId == '' then return false end

    local cached = cacheGet(discordId)
    if cached ~= nil then
        return cached
    end

    local tableName = Config.tableName or 'fivem_dev_whitelist'
    local sql = ('SELECT 1 FROM `%s` WHERE `discord_id` = ? LIMIT 1'):format(tableName)

    local ok, result = pcall(function()
        return MySQL.scalar.await(sql, { discordId })
    end)

    if not ok then
        error(result)
    end

    local allowed = result ~= nil
    cacheSet(discordId, allowed)
    return allowed
end

RegisterCommand('refreshdevwl', function(src)
    if src ~= 0 then
        return
    end
    cacheClear()
    log('Dev whitelist cache cleared')
end, true) 

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    deferrals.defer()
    local src = source

    deferrals.update('Checking Dev whitelist...')

    if not ensureOxmysql() then
        deferrals.done(Config.messages and Config.messages.errorGeneric or 'Whitelist check failed. Please try again.')
        return
    end


    local discordId = getDiscordId(src)
    if not discordId then
        deferrals.done(Config.messages and Config.messages.missingDiscord or 'Discord not detected. Please make sure Discord is running and linked to FiveM.')
        log('DENY missing Discord | name=%s src=%s', tostring(playerName), tostring(src))
        return
    end

    deferrals.update('Validating Discord whitelist...')

    local allowed
    local ok, err = pcall(function()
        allowed = isWhitelisted(discordId)
    end)

    if not ok then
        -- DB error or unexpected failure
        print(('^1[%s] Whitelist DB error for discord_id=%s: %s^7'):format(RESOURCE_NAME, tostring(discordId), tostring(err)))
        deferrals.done(Config.messages and Config.messages.errorGeneric or 'Whitelist check failed. Please try again.')
        log('DENY error | name=%s src=%s discordId=%s', tostring(playerName), tostring(src), tostring(discordId))
        return
    end

    if not allowed then
        deferrals.done(Config.messages and Config.messages.notWhitelisted or 'You are not whitelisted for the Dev server. Please request access.')
        log('DENY not whitelisted | name=%s src=%s discordId=%s', tostring(playerName), tostring(src), tostring(discordId))
        return
    end

    deferrals.update('Whitelist validated. Welcome!')
    deferrals.done()
    log('ALLOW | name=%s src=%s discordId=%s', tostring(playerName), tostring(src), tostring(discordId))
end)

CreateThread(function()
    Wait(500)
    ensureOxmysql()
end)
