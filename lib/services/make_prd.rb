module Services
  class MakePrd < Base
    AGENT_YAML_PATH = './agents/senior_product_manager.yml'
    PROMPT_PATH = './prompts/help_make_prd.md'
    OUTPUT_PATH = './outputs/prd-%{time}.md'
    END_OF_DOCUMENT = '!Document!'
    SPINNER = 'Thinking [:spinner] '

    def initialize(agent_class: Agents::ChainOfThough)
      @agent_class = agent_class
      @tty_prompt_class = TTY::Prompt
      @tty_markdown_parser = TTY::Markdown
      @spinner_class = TTY::Spinner
      @colorizer_class = Pastel
      @file_class = File
    end

    def call
      agent = @agent_class.from_yaml(AGENT_YAML_PATH)
      spinner = @spinner_class.new(SPINNER, format: :bouncing_ball)

      first_step(agent:, spinner:)
      main_loop(agent:, spinner:)
    end

    private

    def first_step(agent:, spinner:)
      task = @file_class.read(PROMPT_PATH)
      agent.ask(content: task)
      agent_response = agent.parse(agent.history.last.content)
      spinner.auto_spin
      puts(@tty_markdown_parser.parse(agent_response['answer']))
      spinner.stop("🎉 Done\n")
    end

    def main_loop(agent:, spinner:)
      colorizer = @colorizer_class.new
      tty_prompt = @tty_prompt_class.new

      Kernel.loop do
        user_input = tty_prompt.multiline(colorizer.yellow('>>> '))
        spinner.auto_spin
        agent.ask(content: user_input.join(''))
        agent_response = agent.parse(agent.history.last.content)
        spinner.stop("🎉 Done\n")
        puts(@tty_markdown_parser.parse(agent_response['answer']))
        if agent_response['final_answer']
          prd = extract_prd(agent_response['answer'])
          @file_class.write(OUTPUT_PATH % {time: Time.now.to_i}, prd.join("\n"))
          return Success(prd)
        end
      end
    end

    def extract_prd(agent_response)
      agent_response['answer'].split("\n").map do |line|
        break if line.include?(END_OF_DOCUMENT)
        line
      end
    end

    def validate_prd(prd)
      # TODO: Implement validation with chain of thought agent and notation, a critic containing good and bad points.
      # Validation depend on a treshold notation.
    end
  end
end
