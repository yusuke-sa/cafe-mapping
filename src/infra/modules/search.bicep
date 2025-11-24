@description('Azure region')
param location string

@description('Search service name (lowercase letters and numbers).')
param searchServiceName string

@description('Search SKU')
@allowed([
  'free'
  'basic'
])
param sku string = 'basic'

@description('Index name')
param indexName string = 'stores-index'

@description('Resource tags')
param tags object = {}

var synonymName = 'synonyms-jp'

resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchServiceName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    hostingMode: 'Default'
    publicNetworkAccess: 'Enabled'
  }
}

// Synonym map for Japanese domain terms
resource synonymMap 'Microsoft.Search/searchServices/synonymMaps@2023-11-01' = {
  name: '${search.name}/${synonymName}'
  properties: {
    format: 'solr'
    synonyms: 'カフェ,喫茶店 => cafe\nレストラン,ダイナー => restaurant\nバー,bar => bar'
  }
}

// Stores index definition (hybrid search)
resource storesIndex 'Microsoft.Search/searchServices/indexes@2023-11-01' = {
  name: '${search.name}/${indexName}'
  properties: {
    fields: [
      {
        name: 'storeId'
        type: 'Edm.String'
        key: true
        filterable: true
        sortable: true
      }
      {
        name: 'name'
        type: 'Edm.String'
        searchable: true
        filterable: true
        sortable: true
        analyzer: 'ja.microsoft'
      }
      {
        name: 'altNames'
        type: 'Collection(Edm.String)'
        searchable: true
        filterable: true
        analyzer: 'ja.microsoft'
      }
      {
        name: 'category'
        type: 'Edm.String'
        searchable: true
        filterable: true
        facetable: true
        analyzer: 'ja.microsoft'
        synonymMaps: [
          synonymName
        ]
      }
      {
        name: 'priceRange'
        type: 'Edm.String'
        filterable: true
        facetable: true
      }
      {
        name: 'address'
        type: 'Edm.String'
        searchable: true
        analyzer: 'ja.microsoft'
      }
      {
        name: 'city'
        type: 'Edm.String'
        filterable: true
        facetable: true
      }
      {
        name: 'regionKey'
        type: 'Edm.String'
        filterable: true
        facetable: true
        sortable: true
      }
      {
        name: 'gridKey'
        type: 'Edm.String'
        filterable: true
        facetable: true
      }
      {
        name: 'location'
        type: 'Edm.GeographyPoint'
        filterable: true
        sortable: true
      }
      {
        name: 'tags'
        type: 'Collection(Edm.String)'
        searchable: true
        filterable: true
        facetable: true
        analyzer: 'ja.microsoft'
        synonymMaps: [
          synonymName
        ]
      }
      {
        name: 'summary'
        type: 'Edm.String'
        searchable: true
        analyzer: 'ja.microsoft'
      }
      {
        name: 'trendScore'
        type: 'Edm.Double'
        filterable: true
        sortable: true
      }
      {
        name: 'crowdLevel'
        type: 'Edm.String'
        filterable: true
        facetable: true
      }
      {
        name: 'popularityScore'
        type: 'Edm.Double'
        filterable: true
        sortable: true
      }
      {
        name: 'rating'
        type: 'Edm.Double'
        filterable: true
        sortable: true
      }
      {
        name: 'reviewCount'
        type: 'Edm.Int32'
        filterable: true
        sortable: true
      }
      {
        name: 'wifi'
        type: 'Edm.Boolean'
        filterable: true
        facetable: true
      }
      {
        name: 'power'
        type: 'Edm.String'
        filterable: true
        facetable: true
      }
      {
        name: 'seats'
        type: 'Edm.Int32'
        filterable: true
        sortable: true
      }
      {
        name: 'priceLevel'
        type: 'Edm.Int32'
        filterable: true
        facetable: true
      }
      {
        name: 'favoriteCount'
        type: 'Edm.Int32'
        filterable: true
        sortable: true
      }
      {
        name: 'heroPhoto'
        type: 'Edm.String'
        retrievable: true
      }
      {
        name: 'placeId'
        type: 'Edm.String'
        filterable: true
        sortable: true
      }
      {
        name: 'etlSources'
        type: 'Collection(Edm.String)'
        filterable: true
        facetable: true
      }
      {
        name: 'lastUpdated'
        type: 'Edm.DateTimeOffset'
        filterable: true
        sortable: true
      }
      {
        name: 'aiUpdatedAt'
        type: 'Edm.DateTimeOffset'
        filterable: true
        sortable: true
      }
      {
        name: 'placesLastFetched'
        type: 'Edm.DateTimeOffset'
        filterable: true
        sortable: true
      }
      {
        name: 'cosmosEtag'
        type: 'Edm.String'
        retrievable: true
      }
      {
        name: 'areaLabels'
        type: 'Collection(Edm.String)'
        searchable: true
        facetable: true
        analyzer: 'ja.microsoft'
      }
      {
        name: 'vectorEmbedding'
        type: 'Collection(Edm.Single)'
        searchable: true
        vectorSearchDimensions: 1536
        vectorSearchProfile: 'vector-profile'
      }
    ]
    suggesters: [
      {
        name: 'sg'
        searchMode: 'analyzingInfixMatching'
        sourceFields: [
          'name'
          'altNames'
          'tags'
          'areaLabels'
        ]
      }
    ]
    semanticSearch: {
      configurations: [
        {
          name: 'semantic-default'
          prioritizedFields: {
            titleField: {
              fieldName: 'name'
            }
            contentFields: [
              {
                fieldName: 'summary'
              }
              {
                fieldName: 'tags'
              }
              {
                fieldName: 'category'
              }
            ]
          }
        }
      ]
    }
    vectorSearch: {
      algorithmConfigurations: [
        {
          name: 'hnsw-profile'
          kind: 'hnsw'
          hnswParameters: {
            m: 40
            efConstruction: 400
            metric: 'cosine'
          }
        }
      ]
      profiles: [
        {
          name: 'vector-profile'
          algorithmConfiguration: 'hnsw-profile'
        }
      ]
    }
    scoringProfiles: [
      {
        name: 'score_popularity'
        text: {}
        functions: [
          {
            type: 'magnitude'
            fieldName: 'popularityScore'
            boost: 3
            parameters: {
              boostingRangeStart: 0
              boostingRangeEnd: 100
              constantBoostBeyondRange: false
            }
          }
          {
            type: 'magnitude'
            fieldName: 'trendScore'
            boost: 1.5
            parameters: {
              boostingRangeStart: 0
              boostingRangeEnd: 1
              constantBoostBeyondRange: false
            }
          }
          {
            type: 'magnitude'
            fieldName: 'rating'
            boost: 1.2
            parameters: {
              boostingRangeStart: 0
              boostingRangeEnd: 5
              constantBoostBeyondRange: false
            }
          }
        ]
        functionAggregation: 'sum'
      }
    ]
    defaultScoringProfile: 'score_popularity'
  }
  dependsOn: [
    synonymMap
  ]
}

output searchServiceId string = search.id
output searchServiceEndpoint string = 'https://${search.name}.search.windows.net'
output searchIndexName string = indexName
