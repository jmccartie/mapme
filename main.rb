require 'rubygems'
require "bundler/setup"
require 'sinatra'
require 'json'
require 'dalli'
require 'digest/md5'

set :cache, Dalli::Client.new()

get '/' do
  check_param(:site)
  content_type :json

  data = settings.cache.get(cache_key())

  if data.nil?
    data = [] 
  else
    data.delete_if { |k| k[:time] <= (Time.now - (60*5))} # trash any times that are older than 5 minutes ago
    save_data(data)
  end

  points = {
    "points" => {
      "point" => data.map {|d| {"ip" => d[:ip]} }
    }
  }

  return points.to_json
end

post '/' do
  check_param(:site)
  data = settings.cache.get(cache_key())
  data = [] if data.nil?

  data.insert(0, {ip: request.ip, time: Time.now})
  save_data(data)

  halt 200
end



private

  def cache_key
    Digest::MD5.hexdigest(params[:site])
  end

  def check_param(param)
    halt 400 if params[param].nil? || params[param].empty?
  end

  def save_data(data)
    settings.cache.set(cache_key, data)
  end