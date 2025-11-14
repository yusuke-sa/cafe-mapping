using '../main.bicep'

param location = 'East Asia'
param staticWebAppName = 'swa-cafemap-dev'
param repositoryUrl = 'https://github.com/yusuke/cafe-mapping'
param branch = 'main'
param appLocation = 'src/frontend'
param apiLocation = ''
param appArtifactLocation = '.next'
param skuName = 'Free'
param tags = {
  project: 'cafe-mapping'
  environment: 'dev'
}
