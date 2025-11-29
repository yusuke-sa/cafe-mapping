using '../main.bicep'

param location = 'East Asia'
param cosmosAccountName = 'cosmos-iijan-map-stg'
param cosmosDatabaseName = 'iijan-map'
param searchServiceName = 'searchiijanmapstg'
param searchSku = 'basic'
param searchIndexName = 'stores-index'
param staticWebAppName = 'swa-iijan-map-stg'
param repositoryUrl = 'https://github.com/yusuke/cafe-mapping'
param branch = 'main'
param appLocation = 'src/apps/frontend'
param apiLocation = ''
param appArtifactLocation = '.next'
param skuName = 'Standard'
param tags = {
  project: 'iijan-map'
  environment: 'stg'
}
