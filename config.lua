Config = {}

Config.tableName = GetConvar('devwl_table', 'fivem_dev_whitelist')
Config.cacheTtlSeconds = 60
Config.messages = {
    missingDiscord = 'Discord not detected. Please make sure Discord is running and linked to FiveM.',
    notWhitelisted = 'You are not whitelisted for the Dev server. Please request access.',
    errorGeneric = 'Whitelist check failed. Please try again.'
}
