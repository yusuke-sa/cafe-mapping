using '../main.bicep'

param location = 'East Asia'
param cosmosAccountName = 'cosmos-iijan-map-prod'
param cosmosDatabaseName = 'iijan-map'
param searchServiceName = 'searchiijanmapprod'
param searchSku = 'basic'
param searchIndexName = 'stores-index'
param staticWebAppName = 'swa-iijan-map-prod'
param repositoryUrl = 'https://github.com/yusuke/cafe-mapping'
param branch = 'main'
param appLocation = 'src/apps/frontend'
param apiLocation = ''
param appArtifactLocation = '.next'
param skuName = 'Standard'
param tags = {
  project: 'iijan-map'
  environment: 'prod'
}
