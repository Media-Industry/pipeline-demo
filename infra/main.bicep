// Where to create everything: the same region as the resource group
param location string = resourceGroup().location

// The three environments we want
var environments = [
  'dev'
  'uat'
  'prod'
]

// A short code like "k3f9x2..." so our app names are unique worldwide
var suffix = uniqueString(resourceGroup().id)

// 1. The server (App Service Plan): Free tier, Linux
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'plan-pipeline-demo'
  location: location
  kind: 'linux'
  sku: {
    name: 'F1'
  }
  properties: {
    reserved: true // means "Linux"
  }
}

// 2. One Web App per environment, all on the same plan
resource apps 'Microsoft.Web/sites@2023-12-01' = [for env in environments: {
  name: 'pipeline-demo-${env}-${suffix}'
  location: location
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|22-lts'
      appCommandLine: 'pm2 serve /home/site/wwwroot --no-daemon --spa'
    }
  }
}]

// 3. After deploying, print the three website addresses
output urls array = [for (env, i) in environments: 'https://${apps[i].properties.defaultHostName}']
