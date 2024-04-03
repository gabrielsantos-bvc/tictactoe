class OpenaiService
  attr_reader :choice

  def initialize(choice)
    @choice = choice
  end
  def call
    if Rails.cache.read("openai_thread_id").nil?
      create_thread
      create_assistant
    end

    client.messages.create(
      thread_id: thread,
      parameters: {
        role: "user",
        content: "I choose #{choice}! Your turn."
      })["id"]

    response = run

    response["content"][0]["text"]["value"]
  end

  private

  def run
    response = client.runs.create(thread_id: thread,
                                  parameters: {
                                    assistant_id: assistant
                                  })
    run_id = response['id']
    while true do

      response = client.runs.retrieve(id: run_id, thread_id: thread)
      status = response['status']

      case status
        when 'queued', 'in_progress', 'cancelling'
          puts 'Sleeping'
          sleep 1 # Wait one second and poll again
        when 'completed'
          break # Exit loop and report result to user
        when 'cancelled', 'failed', 'expired'
          puts response['last_error'].inspect
          break # or `exit`
        else
          puts "Unknown status response: #{status}"
      end
    end

    client.messages.list(thread_id: thread)["data"].first
  end

  def client
    @client = OpenAI::Client.new
  end

  def create_assistant
    response = client.assistants.create(
      parameters: {
        model: "gpt-3.5-turbo-1106",         # Retrieve via client.models.list. Assistants need 'gpt-3.5-turbo-1106' or later.
        name: "OpenAI-Ruby test assistant",
        description: nil,
        instructions: "You are a helpful assistant for coding a OpenAI API client using the OpenAI-Ruby gem.",
        tools: [
          { type: 'retrieval' },           # Allow access to files attached using file_ids
          { type: 'code_interpreter' },    # Allow access to Python code interpreter
        ],
        "metadata": { my_internal_version_id: '1.0.0' }
      })
    Rails.cache.write("openai_assistant_id", response["id"], expires_in: 1.hour)
  end

  def assistant
    Rails.cache.read("openai_assistant_id")
  end

  def thread
    Rails.cache.read("openai_thread_id")
  end

  def create_thread
    response = client.threads.create
    client.messages.create(
      thread_id: response["id"],
      parameters: {
        role: "user",
        content: "Lets play tic tac toe!"
      })["id"]

    Rails.cache.write("openai_thread_id", response["id"], expires_in: 1.hour)
  end
end
