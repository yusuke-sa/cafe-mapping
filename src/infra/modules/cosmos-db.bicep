@description('Azure region')
param location string

@description('Cosmos DB account name (lowercase, numbers, hyphen).')
param accountName string

@description('SQL database name.')
param databaseName string

@description('Resource tags')
param tags object = {}

@description('Deploy Cosmos DB as serverless (mutually exclusive with free tier).')
param enableServerless bool = true

@description('Enable the Cosmos DB free tier (cannot be combined with serverless).')
param enableFreeTier bool = false

var accountProperties = {
  databaseAccountOfferType: 'Standard'
  locations: [
    {
      locationName: location
      failoverPriority: 0
    }
  ]
  capabilities: enableServerless ? [
    {
      name: 'EnableServerless'
    }
  ] : []
  publicNetworkAccess: 'Enabled'
  disableKeyBasedMetadataWriteAccess: true
  consistencyPolicy: {
    defaultConsistencyLevel: 'Session'
  }
}

var freeTierProperties = !enableServerless && enableFreeTier ? {
  enableFreeTier: true
} : {}

resource account 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: accountName
  location: location
  kind: 'GlobalDocumentDB'
  tags: tags
  properties: union(accountProperties, freeTierProperties)
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  name: '${account.name}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
  }
}

// stores container
resource stores 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: '${account.name}/${database.name}/stores'
  properties: {
    resource: {
      id: 'stores'
      partitionKey: {
        paths: [
          '/storeId'
        ]
        kind: 'Hash'
        version: 2
      }
      defaultTtl: -1
      changeFeedPolicy: {
        policyType: 'AllVersionsAndDeletes'
      }
      indexingPolicy: {
        automatic: true
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/storeId/?'
          }
          {
            path: '/name/?'
          }
          {
            path: '/category/?'
          }
          {
            path: '/regionKey/?'
          }
          {
            path: '/gridKey/?'
          }
          {
            path: '/ai/tags/?'
          }
          {
            path: '/popularity/score/?'
            indexes: [
              {
                kind: 'Range'
                dataType: 'Number'
              }
            ]
          }
          {
            path: '/favorites/count/?'
            indexes: [
              {
                kind: 'Range'
                dataType: 'Number'
              }
            ]
          }
          {
            path: '/places/lastFetched/?'
            indexes: [
              {
                kind: 'Range'
                dataType: 'String'
              }
            ]
          }
          {
            path: '/etl/lastUpsert/?'
            indexes: [
              {
                kind: 'Range'
                dataType: 'String'
              }
            ]
          }
        ]
        excludedPaths: [
          {
            path: '/media/*'
          }
          {
            path: '/ai/summary/?'
          }
          {
            path: '/reviews/*'
          }
        ]
        compositeIndexes: [
          [
            {
              path: '/regionKey'
              order: 'ascending'
            }
            {
              path: '/popularity/score'
              order: 'descending'
            }
          ]
          [
            {
              path: '/regionKey'
              order: 'ascending'
            }
            {
              path: '/places/rating'
              order: 'descending'
            }
          ]
          [
            {
              path: '/gridKey'
              order: 'ascending'
            }
            {
              path: '/favorites/count'
              order: 'descending'
            }
          ]
        ]
        spatialIndexes: [
          {
            path: '/coords/?'
            types: [
              'Point'
            ]
          }
        ]
      }
    }
    options: {}
  }
}

// userFavorites container
resource userFavorites 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: '${account.name}/${database.name}/userFavorites'
  properties: {
    resource: {
      id: 'userFavorites'
      partitionKey: {
        paths: [
          '/userId'
        ]
        kind: 'Hash'
        version: 2
      }
      defaultTtl: -1
      changeFeedPolicy: {
        policyType: 'LatestVersion'
      }
      uniqueKeyPolicy: {
        uniqueKeys: [
          {
            paths: [
              '/userId'
              '/storeId'
            ]
          }
        ]
      }
      indexingPolicy: {
        automatic: true
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/userId/?'
          }
          {
            path: '/storeId/?'
          }
          {
            path: '/updatedAt/?'
          }
          {
            path: '/action/?'
          }
          {
            path: '/labels/?'
          }
        ]
        compositeIndexes: [
          [
            {
              path: '/updatedAt'
              order: 'descending'
            }
            {
              path: '/storeId'
              order: 'ascending'
            }
          ]
        ]
      }
    }
    options: {}
  }
}

// geoTiles container
resource geoTiles 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: '${account.name}/${database.name}/geoTiles'
  properties: {
    resource: {
      id: 'geoTiles'
      partitionKey: {
        paths: [
          '/boundsHash'
        ]
        kind: 'Hash'
        version: 2
      }
      defaultTtl: 300
      indexingPolicy: {
        automatic: true
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/boundsHash/?'
          }
          {
            path: '/filters/*'
          }
          {
            path: '/zoom/?'
          }
          {
            path: '/generatedAt/?'
          }
          {
            path: '/featureCount/?'
          }
        ]
        excludedPaths: [
          {
            path: '/geojson/*'
          }
        ]
      }
    }
    options: {}
  }
}

// placeCache container
resource placeCache 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: '${account.name}/${database.name}/placeCache'
  properties: {
    resource: {
      id: 'placeCache'
      partitionKey: {
        paths: [
          '/placeId'
        ]
        kind: 'Hash'
        version: 2
      }
      defaultTtl: 86400
      indexingPolicy: {
        automatic: true
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/placeId/?'
          }
          {
            path: '/storeId/?'
          }
          {
            path: '/lastFetched/?'
          }
          {
            path: '/status/?'
          }
        ]
        excludedPaths: [
          {
            path: '/fields/reviews/*'
          }
        ]
      }
    }
    options: {}
  }
}

// syncState container
resource syncState 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: '${account.name}/${database.name}/syncState'
  properties: {
    resource: {
      id: 'syncState'
      partitionKey: {
        paths: [
          '/scope'
        ]
        kind: 'Hash'
        version: 2
      }
      defaultTtl: 2592000
      indexingPolicy: {
        automatic: true
        indexingMode: 'consistent'
      }
    }
    options: {}
  }
}

output cosmosAccountId string = account.id
output cosmosDatabaseName string = databaseName
