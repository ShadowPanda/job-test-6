Ext.define("LoggedEvent", {extend: "Ext.data.Model", fields: [ "timestamp", "category", "event"]})

Ext.define("Adapter", {
  constructor: ->
    # Create the events log store
    @eventsStore = Ext.create("Ext.data.Store", {model: "LoggedEvent", data: []})
    @

  sendEvent: (eventType, parameters) ->
    switch eventType
      when "log"
        @log(parameters)
      when "data_request"
        @sendData()

  registerEvents: -> @events = window.Plugin.events

  sendData: ->
    # Fetch data from the server
    Ext.Ajax.request({
      url: '/data.json',
      success: (response) =>
        @log({category: "data", event: "New data successfully received."})
        window.Plugin.events.data_answer("data_answer", null, {data: JSON.parse(response.responseText)}) if @events["data_answer"]
      failure: (response) =>
        message = [response.responseText, response.statusText].map((t) -> if t.isBlank() then null else t.trim()).compact().first()
        @log({category: "error", event: "Data retrieval failed: <strong>#{message}</strong>."})
    })

  log: (parameters) ->
    # Prepend the new message
    @eventsStore.insert(0, Object.merge({timestamp: new Date()}, parameters))
    @eventsStore.commitChanges()
})