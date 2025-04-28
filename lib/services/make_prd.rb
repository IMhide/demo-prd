# frozen_string_literal: true

module Services
  class MakePrd < Base
    AGENT_YAML_PATH = './agents/senior_product_manager.yml'
    PROMPT_PATH = './prompts/help_make_prd.md'
    OUTPUT_PATH = './outputs/prd-%{time}.md'
    END_OF_DOCUMENT = '!Document!'
    SPINNER = 'Thinking [:spinner] '
    QUALITY_THRESHOLD = 85

    def initialize(agent: Agents::ChainOfThough.from_yaml(AGENT_YAML_PATH), evaluator_service: Services::EvaluatePrd)
      @agent = agent
      @evaluator_service = evaluator_service
      @tty_prompt = TTY::Prompt.new
      @tty_markdown_parser = TTY::Markdown
      @spinner = TTY::Spinner.new(SPINNER, format: :bouncing_ball)
      @colorizer = Pastel.new
    end

    def call
      llm_input = File.read(PROMPT_PATH)

      Kernel.loop do
        llm_input = llm_input_init(llm_input:)
        agent_response = ask_llm(llm_input:)
        llm_input = nil

        if agent_response['final_answer']
          prd = agent_response['answer'].split(END_OF_DOCUMENT, 2).first
          result = @evaluator_service.call(prd:, quality_threshold: QUALITY_THRESHOLD)

          if result.success?
            File.write(OUTPUT_PATH % {time: Time.now.to_i}, prd)
            return Success(prd)
          else
            llm_input = rework_prd_prompt(result.failure['answer'])
            puts(@colorizer.red("Quality check failed - Score : #{result.failure["answer"]["score"]} Threshold : #{QUALITY_THRESHOLD}"))
          end
        end
      end
    end

    private

    def llm_input_init(llm_input:)
      if llm_input.nil?
        llm_input = @tty_prompt.multiline(@colorizer.yellow('>>> ')).join('')
      else
        puts(@colorizer.yellow(">>> #{llm_input}"))
      end
      llm_input
    end

    def ask_llm(llm_input:)
      @spinner.auto_spin
      @agent.ask(content: llm_input)
      agent_response = @agent.parse(@agent.history.last.content)
      @spinner.stop("🎉 Done\n")
      puts(@tty_markdown_parser.parse(agent_response['answer']))
      agent_response
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
