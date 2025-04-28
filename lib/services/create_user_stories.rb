# frozen_string_literal: true

module Services
  class CreateUserStories < Base
    AGENT_YAML_PATH = './agents/senior_product_owner.yml'
    PROMPT_PATH = './prompts/create_user_stories.md'
    SPINNER = 'Thinking [:spinner] '

    def initialize(agent: Agents::ChainOfThough.from_yaml(AGENT_YAML_PATH))
      @agent = agent
      @tty_prompt = TTY::Prompt.new
      @tty_markdown_parser = TTY::Markdown
      @spinner = TTY::Spinner.new(SPINNER, format: :bouncing_ball)
      @colorizer = Pastel.new
    end

    def call(prd:)
      llm_input = File.read(PROMPT_PATH) + "\n\n#{prd}"

      Kernel.loop do
        if llm_input.nil?
          llm_input = @tty_prompt.multiline(@colorizer.yellow('>>> ')).join('')
        else
          puts(@colorizer.yellow(">>> #{llm_input}"))
        end
        @spinner.auto_spin

        @agent.ask(content: llm_input)
        agent_response = @agent.parse(@agent.history.last.content)
        @spinner.stop("🎉 Done\n")
        puts(@tty_markdown_parser.parse(agent_response['answer']))
        llm_input = nil

        return Success(agent_response) if agent_response['final_answer']
      end
    end
  end
end
