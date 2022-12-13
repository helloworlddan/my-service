require "httparty"
require "json"
require "functions_framework"

FunctionsFramework.cloud_event "approval_trigger" do |event|
  # Configuration
  dynamite_callback = ENV["GOOGLE_CHAT_CALLBACK"]

  # Parse pub/sub message
  action = event.data["message"]["attributes"]["Action"] rescue "unknown"
  rollout = event.data["message"]["attributes"]["Rollout"] rescue "error/unknown"
  
  # Extract rollout infos
  data = { :action => action }
  rollout.split('/').each_slice(2) { |a| data[a.first.chomp("s").to_sym] = a.last }
  
  # Format message
  payload = <<-EOS
Approval #{data[:action].downcase} for #{data[:release]} on #{data[:deliveryPipeline]}
  
Pipeline: #{data[:deliveryPipeline]}
Release:  #{data[:release]}
Rollout:  #{data[:rollout]}
Project:  #{data[:project]}
Location: #{data[:location]}

Review and approve: https://console.cloud.google.com/deploy/delivery-pipelines/#{data[:location]}/#{data[:deliveryPipeline]}/releases/#{data[:release]}/rollouts/#{data[:rollout]}/approve?projectnumber=#{data[:project]}
EOS

  if action == "Approved"
    payload = "Rollout #{data[:action].downcase} for #{data[:release]}: #{data[:rollout]}"
  end
  
  # Push to dynamite
  HTTParty.post(
    dynamite_callback,
    :headers => {"Content-Type" => "application/json; charset=UTF-8" },
    :body => JSON.dump({ "text" => payload })
  )
end
