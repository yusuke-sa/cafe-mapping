@description('Azure region where the Static Web App metadata is stored (e.g. East Asia, Central US).')
param location string

@description('Static Web App resource name (must be globally unique).')
param name string

@description('Pricing tier. Free keeps cost at $0 as per CostEstimation docs.')
@allowed([
  'Free'
  'Standard'
])
param skuName string = 'Free'

@description('GitHub repository URL that hosts the monorepo ( e.g. https://github.com/yusuke/iijan-map ).')
param repositoryUrl string

@description('Branch to build and deploy (typically main).')
param branch string = 'main'

@description('Path to the frontend app relative to repo root (Next.js).')
param appLocation string = 'src/apps/frontend'

@description('Path to the Azure Functions backend relative to repo root. Leave empty until backend is ready.')
param apiLocation string = ''

@description('Build output directory relative to the app location. For Next.js use .next.')
param appArtifactLocation string = '.next'

@description('GitHub PAT or token used for initial workflow hookup. Leave empty to configure manually in the portal.')
@secure()
param repositoryToken string = ''

@description('Common resource tags.')
param tags object = {}

var skuTier = skuName == 'Free' ? 'Free' : 'Standard'

var baseProperties = {
  repositoryUrl: repositoryUrl
  branch: branch
  buildProperties: {
    appLocation: appLocation
    apiLocation: apiLocation
    appArtifactLocation: appArtifactLocation
  }
}

var propertiesWithToken = empty(repositoryToken) ? baseProperties : union(baseProperties, {repositoryToken: repositoryToken})

resource staticSite 'Microsoft.Web/staticSites@2023-06-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: propertiesWithToken
}

output staticWebAppResourceId string = staticSite.id
output defaultHostname string = staticSite.properties.defaultHostname
