targetScope = 'resourceGroup'

@description('Azure region for Static Web App metadata (SWA itself is globally distributed).')
param location string = 'East Asia'

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
param appLocation string = 'src/frontend'

@description('Backend Functions path relative to repo root.')
param apiLocation string = ''

@description('Build output path for the frontend app (relative to appLocation).')
param appArtifactLocation string = '.next'

@description('Optional GitHub token for wiring CI/CD at creation time.')
@secure()
param repositoryToken string = ''

@description('Default resource tags applied to the Static Web App.')
param tags object = {
  project: 'cafe-mapping'
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

output staticWebAppResourceId string = staticWebApp.outputs.staticWebAppResourceId
output staticWebAppDefaultHostname string = staticWebApp.outputs.defaultHostname
