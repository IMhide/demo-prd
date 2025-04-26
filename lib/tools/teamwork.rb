# frozen_string_literal: true

module Tools
  class Teamwork < BaseTool
    define_function :ask_a_teammate, description: 'Ask a specific question to a teammate' do
      property :question, type: 'string', description: 'The question to ask'
      property :teammate, type: 'string', description: 'The identifier of the teammate to ask'
    end

    define_function :delegate_task, description: 'Delegate a specific task to a teammate' do
      property :request, type: 'string', description: <<~PROMPT
        The task to delegate and ALL necessary context to execute the task,
        they know nothing about the task, so share absolutely everything you know,
        don't reference things but instead explain them.'
      PROMPT
      property :output, type: 'string', description: 'The expected output of the task'
      property :teammate, type: 'string', description: 'The identifier of the teammate to delegate the task to'
    end

    def ask_a_teammate(question:, teammate:)
      raise NotImplementedError

      # TODO: Find a way to initialize the agent without AR
      agent = BaseAgent.from_ar(Agent.find_by(identifier: teammate))
      task = BaseTask.new(
        description: "Answer to this question #{question} ",
        expected_output: 'The most precise and complete answer possible'
      )

      assistant = call_agent(system_prompt: agent.full_prompt, user_prompt: task.full_prompt)
      tool_response(content: assistant.messages.last.content)
    end

    def delegate_task(request:, output:, teammate:)
      raise NotImplementedError

      # TODO: Find a way to initialize the agent without AR
      agent = BaseAgent.from_ar(Agent.find_by_identifier(teammate))
      task = BaseTask.new(
        description: "Your teammate gave you this task #{request}, you should help him the best you can",
        expected_output: output
      )

      assistant = call_agent(system_prompt: agent.full_prompt, user_prompt: task.full_prompt)
      tool_response(content: assistant.messages.last.content)
    end

    private

    def call_agent(system_prompt:, user_prompt:)
      assistant = Langchain::Assistant.new(
        llm: Langchain::LLM::OpenAI.new(
          api_key: ENV['OPENAI_API_KEY'],
          default_options: {
            temperature: 0.7,
            chat_model: 'gpt-4o-mini'
          }
        ),
        instructions: system_prompt,
        tools: []
      )
      assistant.add_message_and_run(content: user_prompt)
      assistant
    end
  end
end
