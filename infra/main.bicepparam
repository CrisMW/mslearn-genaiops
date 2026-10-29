using 'main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'trail-guide')
param location = readEnvironmentVariable('AZURE_LOCATION', 'swedencentral')
param aiDeploymentsLocation = readEnvironmentVariable('AZURE_AI_DEPLOYMENTS_LOCATION', 'swedencentral')
param aiFoundryResourceName = readEnvironmentVariable('AZURE_AI_ACCOUNT_NAME', '')
param aiFoundryProjectName = readEnvironmentVariable('AZURE_AI_PROJECT_NAME', 'ai-project-${environmentName}')
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID')
param principalType = readEnvironmentVariable('AZURE_PRINCIPAL_TYPE', 'User')
param enableMonitoring = bool(readEnvironmentVariable('ENABLE_MONITORING', 'true'))
param enableHostedAgents = bool(readEnvironmentVariable('ENABLE_HOSTED_AGENTS', 'true'))
param assignLocalUserFoundryRole = bool(readEnvironmentVariable('ASSIGN_LOCAL_USER_FOUNDRY_ROLE', 'true'))
