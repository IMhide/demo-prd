# frozen_string_literal: true

module Agents
  class Evaluator < Base
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
          type: 'object',
          properties: {
            score: {
              type: 'number',
              description: 'Your score between 0 and 100.'
            },
            good_points: {
              type: 'string',
              description: 'Your good points in markdown format.'
            },
            bad_points: {
              type: 'string',
              description: 'Your bad points in markdown format.'
            }
          }
        },
        final_answer: {
          type: 'boolean',
          description: 'Whether the answer is final.',
          default: true
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

        Give me a score between 0 and 100 and a list of good points and bad points.

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

    def goal
      'Evaluate using the user query using all your knowledge'
    end
  end
end
