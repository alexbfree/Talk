Api = require 'zooniverse/lib/api'
SubStack = require 'lib/sub_stack'
Page = require 'controllers/page'

class Index extends Page
  template: require('views/trending/index')
  
  elements:
    '.subjects .list': 'subjectList'
    '.discussions .help.list': 'helpList'
    '.discussions .science.list': 'scienceList'
    '.discussions .chat.list': 'chatList'
    '.collections .list': 'collectionList'
  
  events:
    'click .load-more': 'loadMore'
  
  constructor: ->
    @subjectsPage = 1
    @collectionsPage = 1
    @discussionPages =
      help: 1
      science: 1
      chat: 1
    
    super
  
  url: =>
    "#{ super }/trending"
  
  # TO-DO: refactor this
  loadMore: (ev) =>
    ev.preventDefault()
    target = $(ev.target)
    type = target.data 'type'
    category = target.data 'category'
    
    switch type
      when 'subjects'
        Api.get "#{ @url() }/subjects?page=#{ @subjectsPage += 1 }&per_page=3", (results) =>
          if results.length > 0
            @subjectList.append require('views/subjects/list')(subjects: results)
          
          if results.length < 3
            target.remove()
      
      when 'discussions'
        Api.get "#{ @url() }/discussions?category=#{ category }&page=#{ @discussionPages[category] += 1 }&per_page=5", (results) =>
          if results.length > 0
            @["#{ category }List"].append require('views/discussions/list')(category: category, discussions: results)
          
          if results.length < 5
            target.remove()
      
      when 'collections'
        Api.get "#{ @url() }/collections?page=#{ @collectionsPage += 1 }&per_page=3", (results) =>
          if results.length > 0
            @collectionList.append require('views/collections/list')(collections: results)
          
          if results.length < 3
            target.remove()

class Trending extends SubStack
  controllers:
    index: Index
  
  routes:
    '/': 'index'
    '/trending': 'index'
  
  default: 'index'
  className: 'stack trending'


module.exports = Trending