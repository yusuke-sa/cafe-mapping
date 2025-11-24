using '../main.bicep'

param location = 'East Asia'
param cosmosAccountName = 'cosmos-iijan-map-dev'
param cosmosDatabaseName = 'iijan-map'
param searchServiceName = 'searchiijanmapdev'
param searchSku = 'basic'
param searchIndexName = 'stores-index'
param staticWebAppName = 'swa-iijan-map-dev'
param repositoryUrl = 'https://github.com/yusuke/cafe-mapping'
param branch = 'main'
param appLocation = 'src/apps/frontend'
param apiLocation = ''
param appArtifactLocation = '.next'
param skuName = 'Free'
param tags = {
  project: 'iijan-map'
  environment: 'dev'
}
