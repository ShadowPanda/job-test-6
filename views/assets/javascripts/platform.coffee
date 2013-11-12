window.Platform = Ext.application({
  name: "Platform",
  launch: ->
    # Create the Adapter
    window.Adapter = Ext.create("Adapter")

    # Create the UI
    Ext.create("Ext.panel.Panel", {
      renderTo: "viewport",
      border: 0,
      width: "100%",
      height: "100%",
      layout: "vbox",
      items: [
        {
          xtype: "panel",
          id: "plugin-container",
          width: "100%",
          flex: 1,
          margin: 10,
          html: '
            <div class="graphs-container">
              <div class="legend-container"><svg class="legend"/></div>
              <div class="data-container"><svg class="data"/></div>
            </div>
          '
        },
        {
          id: "events-log",
          xtype: "gridpanel",
          flex: 1,
          width: "100%",
          margin: 10,
          title: "Events Log",
          store: Adapter.eventsStore,
          enableColumnResize: false,
          enableColumnMove: false,
          columns: [
            {
              text: "Time",
              width: 150,
              sortable: true,
              hideable: false,
              draggable: false,
              dataIndex: "timestamp",
              renderer: Ext.util.Format.dateRenderer('Y-m-d H:i:s.u')
            },
            {
              text: "Category",
              width: 100,
              sortable: true,
              hideable: false,
              draggable: false,
              dataIndex: "category",
              renderer: "uppercase"
            },
            {
              text: "Description",
              sortable: false,
              hideable: false,
              draggable: false,
              dataIndex: "event",
              flex: 1
            }
          ],
          viewConfig: {
            autoFit: true
          }
        }
      ]
    })

    @createPlugin()

  createPlugin: ->
    # Create the plugin
    language = {
      "init_completed": "Initialization completed.",
      "poll_description": "The Plugin will poll every <strong>{{polling_interval}}</strong> seconds, starting in <strong>5</strong> seconds from now.",
      "end_time": "The Plugin will stop polling data at <strong>{{end_time_s}}</strong>",
      "poll_start": "Polling new data ...",
      "poll_end": "Polling completed ...",
      "legend_hovered": "Legend for <strong>{{name}}</strong> hovered.",
      "legend_toggled": "<strong>{{name}}</strong> data toggled.",
      "data_hovered": "Data for <strong>{{name}}</strong> at <strong>{{time}}</strong> hovered.",
      "data_clicked": "Data for <strong>{{name}}</strong> at <strong>{{time}}</strong> clicked."
    }

    bootstrap = Ext.create("Bootstrap", Ext.getCmp("plugin-container").body.id, moment().add(seconds: 10), moment(bootstrap_data.end_time, "YYYY-MM-DD HH:mm:ss"), bootstrap_data.polling_interval)
    window.Plugin = Ext.create("Plugin")
    window.Plugin.init(bootstrap, language, window.Adapter)
})