module Langchain
  class Assistant
    module LLM
      module Adapters
        class OpenAI < Base
          def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
            if content.is_a?(Array)
              content.each do |c|
                puts c.inspect
                content = c[:text] if c[:type] == 'text'
                image_url = c[:image_url][:url] if c[:type] == 'image_url'
              end
            end
            Messages::OpenAIMessage.new(
              role: role,
              content: content,
              image_url: image_url,
              tool_calls: tool_calls,
              tool_call_id: tool_call_id
            )
          end
        end
      end
    end
  end
end
