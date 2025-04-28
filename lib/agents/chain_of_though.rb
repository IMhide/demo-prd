# frozen_string_literal: true

module Agents
  class ChainOfThough < Base
    JSON_SCHEMA = {
      type: 'object',
      properties: {
        thoughts: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              thought: {
                type: 'string',
                description: 'Your thought .'
              },
              reasoning: {
                type: 'string',
                description: 'Your reasoning behind the thought.'
              }
            }
          }
        },
        answer: {
          type: 'string',
          description: 'Your answer to the user in markdown format. Only this property shoud be in markdown format.'
        },
        final_answer: {
          type: 'boolean',
          description: 'An answer is final if you think that you\'re done with the task and the user confirmed you that is finished.',
          default: false
        }
      }
    }.freeze

    attr_reader :parser

    def initialize(*)
      @parser = Langchain::OutputParsers::StructuredOutputParser.from_json_schema(JSON_SCHEMA)
      super
    end

    def parse(content)
      @parser.parse(content)
    end

    def full_prompt
      <<~PROMPT
        #{super}

        #{chain_of_though}
      PROMPT
    end

    def chain_of_though
      <<~PROMPT
        You need to think step by step to solve the task.
        IMPORTANT: Use the following format in your response

        #{@parser.get_format_instructions}

        Your answer should ALWAYS be a RAW valid JSON object that conforms to the JSON schema above.
      PROMPT
    end
  end
end
