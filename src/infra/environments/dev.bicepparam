using '../main.bicep'

param location = 'East Asia'
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
