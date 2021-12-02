/*
  Deploy a Portal Dashboard
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The website name')
param websiteName string

@description('The Application Insights name')
param applicationInsightsName string

// === VARIABLES ===

var location = resourceGroup().location

// === EXISTING ===

@description('Web application')
resource website 'Microsoft.Web/sites@2021-02-01' existing = {
  name: websiteName
}

@description('Application insights')
resource ai 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

// === RESOURCES ===

@description('Dashboard')
resource dashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.dashboard}'
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
                            id: website.id
                          }
                          name: 'FunctionExecutionCount'
                          aggregationType: 1
                          metricVisualization: {
                            displayName: 'Function execution count'
                            resourceDisplayName: website.name
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
              settings: {}
            }
          }
          {
            position: {
              x: 4
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
                            id: website.id
                          }
                          name: 'FunctionExecutionUnits'
                          aggregationType: 1
                          metricVisualization: {
                            displayName: 'Function execution units'
                            resourceDisplayName: website.name
                          }
                        }
                      ]
                      title: 'MB Milliseconds'
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
              settings: {}
            }
          }
          {
            position: {
              x: 8
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
                            id: ai.id
                          }
                          name: 'requests/duration'
                          aggregationType: 4
                          namespace: 'microsoft.insights/components'
                          metricVisualization: {
                            displayName: 'Server response time'
                            resourceDisplayName: website.name
                          }
                        }
                      ]
                      title: 'Server response time'
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
              settings: {}
            }
          }
          {
            position: {
              x: 0
              y: 4
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
                            id: ai.id
                          }
                          name: 'requests/failed'
                          aggregationType: 7
                          namespace: 'microsoft.insights/components'
                          metricVisualization: {
                            displayName: 'Failed requests'
                            resourceDisplayName: website.name
                            color: '#EC008C'
                          }
                        }
                      ]
                      title: 'Failed requests'
                      titleKind: 2
                      visualization: {
                        chartTpe: 3
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
              settings: {}
            }
          }
          {
            position: {
              x: 4
              y: 4
              rowSpan: 4
              colSpan: 8
            }
            metadata: {
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
              inputs: [
                {
                  name: 'resourceTypeMode'
                }
                {
                  name: 'ComponentId'
                }
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      ai.id
                    ]
                  }
                }
                {
                  name: 'Version'
                  value: '2.0'
                }
                {
                  name: 'TimeRange'
                  value: 'PT24H'
                }
                {
                  name: 'DashboardId'
                }
                {
                  name: 'DraftRequestParameters'
                }
                {
                  name: 'Query'
                  value: 'requests summarize count() by operation_Name, bin(timestamp, 1m)'
                }
                {
                  name: 'ControlType'
                  value: 'FrameControlChart'
                }
                {
                  name: 'SpecificChart'
                  value: 'StackedColumn'
                }
                {
                  name: 'PartTitle'
                  value: 'Analytics'
                }
                {
                  name: 'PartSubTitle'
                  value: website.name
                }
                {
                  name: 'Dimensions'
                  value: {
                    xAxis: {
                      name: 'timestamp'
                      type: 'datetime'
                    }
                    yAxis: [
                      {
                        name: 'count_'
                        type: 'long'
                      }
                    ]
                    splitBy: [
                      {
                        name: 'operation_Name'
                        type: 'string'
                      }
                    ]
                    aggregation: 'Sum'
                  }
                }
                {
                  name: 'LegendOptions'
                  value: {
                    isEnabled: true
                    position: 'Bottom'
                  }
                }
                {
                  name: 'IsQueryContainTimeRange'
                  value: false
                }
              ]
              settings: {
                content: {
                  PartTitle: 'Function calls'
                  PartSubTitle: website.name
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
              duration: 24
              timeUnit: 1
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
