# frozen_string_literal: true

require 'yaml'

module Agents
  class Base < Dry::Struct
    class NotAToolError < StandardError; end

    module Types
      include Dry.Types()
    end

    attribute :name, Types::Coercible::String
    attribute :role, Types::Coercible::String
    attribute :goal, Types::Coercible::String
    attribute :backstory, Types::Coercible::String
    attribute :tools, Types::Array.of(Types.Instance(Tools::Base)).default([].freeze)
    attribute :teammates, Types::Array.of(Types.Instance(Agents::Base)).default([].freeze)

    attr_reader :assistant, :tools

    def self.from_yaml(path)
      new(**YAML.load_file(path, symbolize_names: true))
    end

    def initialize(*)
      super(*)
      @assistant = Langchain::Assistant.new(
        llm: Langchain::LLM::OpenAI.new(
          api_key: ENV['OPENAI_API_KEY'],
          default_options: {
            temperature: 0.7,
            chat_model: 'gpt-4.1-mini'
          }
        ),
        instructions: full_prompt,
        tools: tools || [],
        parallel_tool_calls: false
      )
      if teammates.any?
        @assistant.tools << Tools::Teamwork.new
      end
    end

    def ask(content)
      @assistant.add_message_and_run(content:, auto_tool_execution: true)
    end

    def add_history(messages)
      @assistant.clear_messages!
      @assistant.add_messages(messages:)
    end

    def history
      @assistant.messages
    end

    #
    # Prompts
    #

    def full_prompt
      <<~PROMPT
        #{persona_prompt}

        #{teammates_prompt}
      PROMPT
    end

    protected

    def persona_prompt
      <<~PROMPT
        You are #{role}. #{backstory}
        Your personal goal is: #{goal}
      PROMPT
    end

    def teammates_prompt
      if teammates.any?
        <<~PROMPT

          You are a member of a team that is composed of the following teammates:
          #{teammates.map { |teammate| "#{teammate.identifer} - #{teammate.role}" }.join("\n")}
        PROMPT
      end
    end
  end
end
