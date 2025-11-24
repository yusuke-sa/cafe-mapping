targetScope = 'resourceGroup'

@description('Azure region for Static Web App metadata (SWA itself is globally distributed).')
param location string = 'East Asia'

@description('Cosmos DB account name (serverless).')
param cosmosAccountName string

@description('Cosmos DB SQL database name.')
param cosmosDatabaseName string = 'iijan-map'

@description('Search service name.')
param searchServiceName string

@description('Search SKU.')
@allowed([
  'free'
  'basic'
])
param searchSku string = 'basic'

@description('Search index name.')
param searchIndexName string = 'stores-index'

@description('Static Web App resource name (lowercase letters, numbers, and hyphens).')
param staticWebAppName string

@description('Pricing tier for Static Web Apps.')
@allowed([
  'Free'
  'Standard'
])
param skuName string = 'Free'

@description('Repository URL that hosts the monorepo (frontend/backend/IaC).')
param repositoryUrl string

@description('Branch name to deploy.')
param branch string = 'main'

@description('Frontend app path relative to repo root.')
param appLocation string = 'src/apps/frontend'

@description('Backend Functions path relative to repo root.')
param apiLocation string = ''

@description('Build output path for the frontend app (relative to appLocation).')
param appArtifactLocation string = '.next'

@description('Optional GitHub token for wiring CI/CD at creation time.')
@secure()
param repositoryToken string = ''

@description('Default resource tags applied to the Static Web App.')
param tags object = {
  project: 'iijan-map'
  environment: 'dev'
}

module staticWebApp './modules/static-web-app.bicep' = {
  name: 'swa-${uniqueString(resourceGroup().id, staticWebAppName)}'
  params: {
    location: location
    name: staticWebAppName
    skuName: skuName
    repositoryUrl: repositoryUrl
    branch: branch
    appLocation: appLocation
    apiLocation: apiLocation
    appArtifactLocation: appArtifactLocation
    repositoryToken: repositoryToken
    tags: tags
  }
}

module cosmos './modules/cosmos-db.bicep' = {
  name: 'cosmos-${uniqueString(resourceGroup().id, cosmosAccountName)}'
  params: {
    location: location
    accountName: cosmosAccountName
    databaseName: cosmosDatabaseName
    tags: tags
  }
}

module search './modules/search.bicep' = {
  name: 'search-${uniqueString(resourceGroup().id, searchServiceName)}'
  params: {
    location: location
    searchServiceName: searchServiceName
    sku: searchSku
    indexName: searchIndexName
    tags: tags
  }
}

output staticWebAppResourceId string = staticWebApp.outputs.staticWebAppResourceId
output staticWebAppDefaultHostname string = staticWebApp.outputs.defaultHostname
output cosmosAccountId string = cosmos.outputs.cosmosAccountId
output cosmosDatabaseName string = cosmos.outputs.cosmosDatabaseName
output searchServiceId string = search.outputs.searchServiceId
output searchServiceEndpoint string = search.outputs.searchServiceEndpoint
output searchIndexNameOut string = search.outputs.searchIndexName
