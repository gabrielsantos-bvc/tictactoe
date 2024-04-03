OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_KEY", "your-api-key-here")
end
