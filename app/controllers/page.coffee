{Controller} = require 'spine'
{ project, apiHost } = require 'lib/config'
Api = require 'zooniverse/lib/api'
$ = require 'jqueryify'

class Page extends Controller
  tagName: 'section'
  className: 'page'
  template: null
  data: null
  fetchOnLoad: true
  
  events:
    'click .add-to-collection .collect-this': 'showCollectionList'
    'click .add-to-collection .collection-list .collection': 'collectSubject'
  
  constructor: ->
    super
    @data ?= {}

  activate: (params) ->
    return unless params
    super

    @el.addClass 'loading'
    @reload => @el.removeClass 'loading'

  url: ->
    "/projects/#{ project }/talk"

  reload: (callback) ->
    if @fetchOnLoad
      Api.get @url(), (@data) =>
        @render()
        callback @data
    else
      @data = @
      @render()
      callback? @

  render: ->
    @html @template? @data
  
  showCollectionList: (ev) =>
    ev.preventDefault()
    collection = $(ev.target).closest '.add-to-collection'
    list = collection.find '.collection-list'
    
    list.addClass 'loading'

    Api.get "/projects/#{ project }/talk/users/collection_list", (results) =>
      list.removeClass 'loading'
      list.show()
      list.html require('views/users/collection_list') subject: @data, collections: results

  collectSubject: (ev) =>
    ev.preventDefault()
    collectionId = $(ev.target).data 'id'
    collection = $(ev.target).closest '.add-to-collection'
    list = collection.find '.collection-list'
    button = collection.find '.collect-this'
    subjectId = button.data 'id'
    
    Api.post "/projects/#{ project }/talk/collections/#{ collectionId }/add_subject", subject_id: subjectId, (results) =>
      list.html ''
      list.hide()
      button.text 'Collected'

module.exports = Page
