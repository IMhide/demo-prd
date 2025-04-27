module Services
  class MakePrd < Base
    AGENT_YAML_PATH = './agents/senior_product_manager.yml'
    PROMPT_PATH = './prompts/help_make_prd.md'
    OUTPUT_PATH = './outputs/prd-%{time}.md'
    END_OF_DOCUMENT = '!Document!'
    SPINNER = 'Thinking [:spinner] '
    QUALITY_THRESHOLD = 85

    def initialize(agent_class: Agents::ChainOfThough, evaluator_service: Services::EvaluatePrd)
      @agent_class = agent_class
      @evaluator_service = evaluator_service
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
      prd = main_loop(agent:, spinner:)
      Success(prd)
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
      llm_input = nil

      Kernel.loop do
        if llm_input.nil?
          llm_input = tty_prompt.multiline(colorizer.yellow('>>> ')).join('')
        else
          puts(colorizer.yellow(">>> #{llm_input}"))
        end

        spinner.auto_spin

        agent.ask(content: llm_input)
        agent_response = agent.parse(agent.history.last.content)

        spinner.stop("🎉 Done\n")
        puts(@tty_markdown_parser.parse(agent_response['answer']))
        llm_input = nil

        if agent_response['final_answer']
          prd = extract_prd(agent_response['answer'])
          result = @evaluator_service.call(prd:, quality_threshold: QUALITY_THRESHOLD)

          Dry::Matcher::ResultMatcher.call(result) do |matcher|
            matcher.failure do |failure|
              llm_input = rework_prd_prompt(failure['answer'])
              puts(colorizer.red("Quality check failed - Score : #{failure["answer"]["score"]} Threshold : #{QUALITY_THRESHOLD}"))
            end
            matcher.success do |success|
              @file_class.write(OUTPUT_PATH % {time: Time.now.to_i}, prd)
              return prd
            end
          end
        end
      end
    end

    def extract_prd(agent_response)
      agent_response.split('!Document!', 2).first
    end

    def rework_prd_prompt(evaluation)
      <<~PROMPT
        This PRD is not good enough. Please rework it.

        Here is the good points:
        #{evaluation["good_points"]}
        Here is the bad points:
        #{evaluation["bad_points"]}
      PROMPT
    end
  end
end
