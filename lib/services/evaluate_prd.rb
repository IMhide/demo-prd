# frozen_string_literal: true

module Services
  class EvaluatePrd < Base
    AGENT_YAML_PATH = './agents/senior_product_manager.yml'
    SPINNER = 'Thinking [:spinner] '

    def initialize(evaluator_class: Agents::Evaluator)
      @evaluator_class = evaluator_class
      @spinner_class = TTY::Spinner
      @colorizer_class = Pastel
      @file_class = File
    end

    def call(prd:, quality_threshold:)
      evaluator = @evaluator_class.from_yaml(AGENT_YAML_PATH)
      spinner = @spinner_class.new(SPINNER, format: :bouncing_ball)

      spinner.auto_spin
      evaluator.ask("Evaluate the following Product Requirements Document (PRD) using all your knowledge. \n\n#{prd}")
      evaluation = evaluator.parse(evaluator.history.last.content)
      spinner.stop("🎉 Done\n")

      if evaluation['answer']['score'] < quality_threshold
        Failure(evaluation)
      else
        Success(evaluation)
      end
    end
  end
end
