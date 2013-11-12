Ext.define("Bootstrap", {
  plugin_id: ""
  start_time: null
  end_time: null
  polling_interval: 5

  constructor: (plugin_id, start_time, end_time, polling_interval) ->
    @plugin_id = plugin_id
    @start_time = start_time
    @end_time = end_time
    @end_time_s = @end_time.format("DD/MM/YYYY, HH:mm:ss")
    @polling_interval = polling_interval
    @
})

Ext.define("Plugin", {
  constructor: ->
    @relevances = [
      {name: "Severe", value: 0, color: "#D1333F"},
      {name: "High", value: 0, color: "#F69C35"},
      {name: "Elevated", value: 0, color: "#F5D711"},
      {name: "Guarded", value: 0, color: "#3473AE"},
      {name: "Low", value: 0, color: "#199969"}
    ]

    @events = {
      "data_answer": (eventType, sender_id, parameters) =>
        @appendData(parameters["data"])
        @updateLegendGraph()
        @updateDataGraph()
    }

    @counter = 0
    @threshold = 9
    @legendScale = d3.scale.linear().range([0, 100])
    @updateLegendScale()
    @

  init: (bootstrap, language, adapter) ->
    # Save the initialization parameters
    @data = []
    @bootstrap = bootstrap
    @language = language
    @adapter = adapter

    # Setup the polling interval, starting in 5 seconds
    setTimeout((=> @interval = setInterval((=> @poll()), @bootstrap.polling_interval * 1000)), 5000)

    @adapter.registerEvents()
    @adapter.sendEvent("log", {category: "general", event: @language["init_completed"]})
    @adapter.sendEvent("log", {category: "general", event: Handlebars.compile(@language["poll_description"])(@bootstrap)})
    @adapter.sendEvent("log", {category: "general", event: Handlebars.compile(@language["end_time"])(@bootstrap)})

    @prepareGraphs()

  poll: ->
    # We are still before end_time
    if moment().isBefore(@bootstrap.end_time)
      @adapter.sendEvent("data_request")
      @adapter.sendEvent("log", {category: "plugin", event: @language["poll_start"]})
    else
      clearInterval(@interval)
      @adapter.sendEvent("log", {category: "plugin", event: @language["poll_end"]})

  prepareGraphs: ->
    @renderLegend()
    @prepareData()

  renderLegend: ->
    self = @
    @legend_canvas = d3.select("#viewport svg.legend")
    legend_canvas_height = parseInt(@legend_canvas.style("height"))

    @updateLegendTicks()

    # Specify a container which leaves margin on top and bottom, to align to the data timeline
    @legend_canvas.append("line").attr({x1: "100%", y1: "0", x2: "100%", y2: "100%", class: "separator"})
    @legend_container = @legend_canvas.append("g").attr("transform", "translate(0,#{legend_canvas_height / 10})").append("svg").attr({width: "100%", height: legend_canvas_height * 0.8})

    # Get canvas sizes
    legend_height = parseInt(@legend_container.attr("height"))
    legend_bar_height = legend_height / (@relevances.count())

    # Create the bars roots
    legend_groups = @legend_container.selectAll("g").data(@relevances, (d, i) -> i).enter().append("g").attr(class: ((d, i) -> "relevance relevance-#{i}"), transform: ((d, i) -> "translate(0, #{0.1 * legend_bar_height + i * legend_bar_height})"))
    legend_groups.on("mouseover", (d, i) -> self.onLegendHovered(@, d, i)).on("click", (d, i) -> self.onLegendToggled(@, d, i))
    @max_circle_height = legend_bar_height * 0.8
    legend_bars = legend_groups.append("svg").attr("height", @max_circle_height)

    # Create the trace lines
    legend_bars.append("line").attr({x1: "0%", y1: "50%", x2: "100%", y2: "50%"})

    # Create the labels
    legend_bars.append("rect").attr({width: ((d) => @legendScale(d.value)), height: legend_bar_height * 0.8, fill: ((d) -> d.color)})
    legend_bars.append("text").attr({x: "3%", y: "50%"}).text((d) -> "#{d.name} (#{d.value})")

  updateLegendScale: -> @legendScale.domain([0, d3.max(@relevancesCount()) * 1.1])

  updateLegendGraph: ->
    @updateLegendScale()

    # Update data
    changed = @legend_container.selectAll("g").data(@relevances)

    # Update elements
    changed.select("text").text((d) -> "#{d.name} (#{d.value})")
    changed.select("rect").transition().duration(300).attr("width", (d) => @legendScale(d.value) + "%")

    # Update ticks
    @updateLegendTicks()

  updateLegendTicks: ->
    # Collect data
    max = (@legendScale.domain()[1] * 1.1).ceil()
    tickData = [0...4].map((i) -> parseInt(max * 0.2 * (i + 1)))
    ticks = @legend_canvas.selectAll("g.ticks").data(tickData)

    # Create and/or update the grid ticks
    ticks.select("text").text((d) -> d)
    new_ticks = ticks.enter().append("g").attr("class", "ticks")
    new_ticks.append("line").attr({x1: ((d, i) -> "#{(i + 1) * 20}%"), y1: "0%", x2: ((d, i) -> "#{(i + 1) * 20}%"), y2: "100%"})
    new_ticks.append("text").attr({x: ((d, i) -> "#{(i + 1) * 20}%"), y: "95%", class: "tick"})

  # This returns the sum of occurences of each relevance level
  relevancesCount: -> @relevances.map((relevance) -> relevance.value)

  # This return the offset for placing a circle in the right Y position
  relevanceY: (d, i) -> "#{10 + (0.8 * (10 + (20 * i)))}%"

  prepareData: ->
    # Create the data graph, for now only the horizontal guides
    @data_height = parseFloat(d3.select("#viewport svg.data").style("height"))
    d3.select("#viewport svg.data").append("g").attr("id", "grid").selectAll("g#grid").data(@relevances).enter().append("line").attr(x1: "0%", y1: @relevanceY, x2: "100%", y2: @relevanceY)
    @data_canvas = d3.select("#viewport svg.data").append("g").attr("id", "data")

  appendData: (data) ->
    key = null
    values = [0...@relevances.length].map(-> 0)

    # Build the new array entry - The key for each append is the first date, dropping millisecond part
    for single_data in data["graph_data"]
      key = single_data["t"].replace(/.\d{3}$/, "") if !key?

      # Calculate the sum of occurences for each level.
      for entry in single_data["data"]
        values[entry.relevance] += entry.size

    # Now add the new data to the plugin
    @data.unshift({timestamp: key, values: values})
    @data.pop() if @data.length > @threshold # Make sure we delete older entries

    # Update the sums count
    @relevances[i].value += value for value, i in values

  updateDataGraph: ->
    newX = (d, i) -> "#{90 - (10 * i)}%"

    self = @
    relevances_count = @relevances.length
    variation = @data_canvas.selectAll("g").data(@data, (d) -> d.timestamp)

    # Shift old entries on the left
    variation.each((d, i) ->
      group = d3.select(@)
      new_x = "#{90 - (10 * i)}%"

      # Translate the line, the circle and the text
      group.select("line").transition().duration(300).attr({x1: new_x, x2: new_x})
      group.selectAll("circle").transition().duration(300).attr("cx", new_x)
      group.selectAll("rect, text").transition().duration(300).attr("x", new_x)
    )

    # Add new entries
    news = variation.enter().append("g").each((d, i) ->
      x = newX(0, i)

      total = 0
      group = d3.select(@)

      # Initially all the elements are outside the svg
      # Add the vertical line
      group.append("line").attr({x1: "110%", y1: "0%", x2: "110%", y2: "100%"}).transition().duration(300).attr({x1: newX, x2: newX})

      # Add the circle for each level
      for value, relevance in d.values
        radius = value / 500 * (self.max_circle_height / 2)
        total += value
        group.append("circle").attr(class: "relevance-#{relevance}", "data-relevance": relevance)
          .on("mouseover", (d, i) -> self.onDataHovered(@, d, i))
          .on("click", (d, i) -> self.onDataToggled(@, d, i))
          .attr({cx: "110%", cy: self.relevanceY(0, relevance), r: radius, fill: self.relevances[relevance].color})
          .transition().duration(300).attr("cx", x)

        group.selectAll("circle").style("opacity", "0.3") if self.legend_container.selectAll("g.relevance-#{relevance}").attr("class").indexOf("toggled") != -1


      # Now add the legends above and below
      group.append("text").attr({x: "110%", y: "5%"}).text((d, i) -> total).transition().duration(300).attr("x", newX)
      group.append("text").attr({x: "110%", y: "95%"}).text((d, i) -> d.timestamp.replace(/.+\s(.+)$/, "$1")).transition().duration(300).attr("x", newX)
    )

    # Remove expired entries
    variation.exit().remove()

  onLegendHovered: (context, d, i) ->
    @adapter.sendEvent("log", {category: "event", event: Handlebars.compile(@language["legend_hovered"])(d)})

  onLegendToggled: (context, d, i) ->
    context = d3.select(context)
    @adapter.sendEvent("log", {category: "event", event: Handlebars.compile(@language["legend_toggled"])(d)})

    # Toggle the serie
    if context.attr("class").indexOf("toggled") == -1
      context.classed("toggled", true)
      d3.selectAll(".relevance-#{i}").classed("toggled", true).transition().duration(300).style("opacity", "0.3")
    else
      context.classed("toggled", false)
      d3.selectAll(".relevance-#{i}").classed("toggled", false).transition().duration(300).style("opacity", "1")

  onDataHovered: (context, d, i) ->
    context = d3.select(context)

    # Ignore events for toggled series
    if context.attr("class").indexOf("toggled") == -1
      # Gather arguments
      relevance = parseInt(context.attr("data-relevance"))
      args = {name: @relevances[relevance].name, time: d.timestamp.replace(" ", ", ")}

      # Log event
      @adapter.sendEvent("log", {category: "event", event: Handlebars.compile(@language["data_hovered"])(args)})

  onDataToggled: (original_context, d, i) ->
    self = @
    context = d3.select(original_context)
    classes = context.attr("class")

    # Ignore events for toggled series
    if classes.indexOf("toggled") == -1
      # Gather arguments
      relevance = parseInt(context.attr("data-relevance"))
      args = {name: @relevances[relevance].name, time: d.timestamp.replace(" ", ", ")}

      # Log event
      @adapter.sendEvent("log", {category: "event", event: Handlebars.compile(@language["data_clicked"])(args)})

      # Remove any existing tooltip
      @data_canvas.selectAll(".data-tooltip").remove()

      if classes.indexOf("with-tooltip") == -1
        context.classed("with-tooltip", true)
        # Make some calculation
        x = context.attr("cx")
        y = context.attr("cy")
        root = d3.select(context.node().parentNode)
        radius = parseFloat(context.attr("r"))
        tx = (@max_circle_height / 2) * 0.8

        # Create the highlight circle and the tooltip
        root.append("circle").attr({class: "data-tooltip", cx: x, cy: y, r: radius * 2}).on("click", -> self.onDataToggled(original_context, d, i))
          .transition().duration(300).attr("r", radius)
        root.append("rect").attr({x: x, y: y, rx: 5, ry: 5, width: "40", height: "20", class: "data-tooltip", transform: "translate(#{tx}, -10)"})
          .style("opacity", 0).transition().duration(300).attr("r", radius).style("opacity", 1)
        root.append("text").attr({x: x, y: y, class: "data-tooltip", transform: "translate(#{(tx + 20)}, 0)"}).text(d.values[relevance])
          .style("opacity", 0).transition().duration(300).attr("r", radius).style("opacity", 1)
      else
        context.classed("with-tooltip", false)
})