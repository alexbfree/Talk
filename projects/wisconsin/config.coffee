socialDefaults =
  href: 'http://talk.snapshotwisconsin.org/'
  title: 'Snapshot Wisconsin'
  summary: 'Help us to identify the animals captured on camera and better understand the distribution and trends of our wildlife populations.'
  image: 'http://www.snapshotwisconsin.org/images/home.jpg'
  twitterTags: 'via @wisconsin'

app =
  categories: ['help', 'science', 'chat']

Config =
  test:
    project: 'wisconsin'
    projectName: 'Snapshot Wisconsin'
    prefix: 'WZ'
    apiHost: null
    classifyUrl: null
    socialDefaults: socialDefaults
    analytics: { }
    app: app
  
  developmentLocal:
    project: 'wisconsin'
    projectName: 'Snapshot Wisconsin'
    prefix: 'WZ'
    apiHost: 'http://localhost:3000'
    classifyUrl: 'http://localhost:9294/#/classify'
    socialDefaults: socialDefaults
    analytics: { }
    app: app
  
  developmentRemote:
    project: 'wisconsin'
    projectName: 'Snapshot Wisconsin'
    prefix: 'WZ'
    apiHost: 'https://dev.zooniverse.org'
    classifyUrl: 'http://deom.zooniverse.org/wisconsin-zoo/#/classify'
    socialDefaults: socialDefaults
    analytics: { }
    app: app
  
  production:
    project: 'wisconsin'
    projectName: 'Snapshot Wisconsin'
    prefix: 'WZ'
    apiHost: 'https://api.zooniverse.org'
    classifyUrl: 'http://www.snapshotwisconsin.org/#/classify'
    socialDefaults: socialDefaults
    analytics:
      account: 'UA-53428944-5'
      domain: 'http://talk.snapshotwisconsin.org'
    app: app

env = if window.jasmine
  'test'
else if window.location.port is '9295'
  'developmentLocal'
else if window.location.port > 1024 
  'developmentRemote'
else
  'production'

module.exports = Config[env]
