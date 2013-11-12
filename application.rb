#!/usr/bin/env ruby
#
# This file is part of the job-test-6. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "sinatra"
require "sass"
require "coffee-script"
require "oj"
require "slim"

configure do
  set(:sass, {output_style: :compact, line_comments: false})
end

configure(:development) do
  set(:bind, "0.0.0.0")
  set(:port, 21080)
end

get /^(?<path>\/assets\/.+)\.css$/ do
  content_type("text/css", charset: "utf-8")
  sass(params[:path].to_sym)
end

get /^(?<path>\/assets\/.+)\.js/ do
  content_type("text/javascript", charset: "utf-8")
  coffee(params[:path].to_sym)
end

get "/data.json" do
  content_type("application/json", charset: "utf-8")
  now = Time.now.to_f
  base = 25

  Oj.dump({
    graph_data: (1 + rand(5)).times.collect { |i|
      offset = (((i + 1) * 100) + rand(100)).to_f / 1000

      {
        t: Time.at(now + offset).strftime("%F %T.%L"),
        data: [
          {relevance: 0, size: base + rand(60)},
          {relevance: 1, size: base + rand(80)},
          {relevance: 2, size: base + rand(40)},
          {relevance: 3, size: base + rand(100)},
          {relevance: 4, size: base + rand(20)}
        ]
      }
    }
  }, mode: :compat)
end

get /.*/ do
  @polling_interval = [2, params[:polling_interval].to_i].max
  end_time = DateTime.strptime(params[:end_time], "%F %T") rescue (Time.at(Time.now + 600))
  @end_time = end_time.strftime("%F %T")
  slim(:index)
end