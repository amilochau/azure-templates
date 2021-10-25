/*
  Deploy an Azure Portal Dashboard
  Resources deployed from this template:
    - Dashboard
  Required parameters:
    - `referential`
    - `conventions`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The Functions ID')
param functionsName string

// === VARIABLES ===

var location = resourceGroup().location

// === EXISTING ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-02-01' existing = {
  name: functionsName
}

// === RESOURCES ===

@description('Dashboard')
resource dashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: conventions.naming.dashboard.name
  location: location
  tags: referential
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              rowSpan: 4
              colSpan: 4
            }
            metadata: {
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: fn.id
                          }
                          name: 'FunctionExecutionCount'
                          aggregationType: 1
                          metricVisualization: {
                            displayName: 'Function execution count'
                            resourceDisplayName: fn.name
                          }
                        }
                      ]
                      title: 'Function execution count'
                      titleKind: 2
                      visualization: {
                        chartTpe: 2
                      }
                      openBladeOnClick: {
                        openBlade: true
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: fn.id
                          }
                          name: 'FunctionExecutionCount'
                          aggregationType: 1
                          displayName: {
                            displayName: 'Function execution count'
                            resourceDisplayName: fn.name
                          }
                        }
                      ]
                      title: 'Function execution count'
                      titleKind: 2
                      visualization: {
                        chartTpe: 2
                        disablePinning: true
                      }
                      openBladeOnClick: {
                        openBlade: true
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
          value: {
            relative: {
              duration: 1
              timeUnit: 2
            }
          }
        }
        filterLocale: {
          value: 'en-us'
        }
        filters: {
          value: {
            'MsPortalFx_TimeRange': {
              model: {
                format: 'local'
                granularity: 'auto'
                relative: '1h'
              }
              displayCache: {
                name: 'Local Time'
                value: 'Past hour'
              }
            }
          }
        }
      }
    }
  }
}

// === OUTPUTS ===

output id string = dashboard.id
output apiVersion string = dashboard.apiVersion
output name string = dashboard.name
