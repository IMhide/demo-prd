# frozen_string_literal: true

module Tools
  class Linear < Base
    define_function :create_task, description: 'Allows you to create a Task in Linear' do
      property :title, type: 'string', description: 'The title of the Task'
      property :description, type: 'string', description: 'The content of the Task'
    end

    def create_task(title:, description:)
      query = <<-GRAPHQL
  mutation IssueCreate($input: IssueCreateInput!) {
    issueCreate(input: $input){
      success
    }
  }
      GRAPHQL

      HTTP.post('https://api.linear.app/graphql', headers: {
                                                    'Authorization' => "Bearer #{ENV["LINEAR_TOKEN"]}",
                                                    'Content-Type' => 'application/json'
                                                  },
        json: {query: query, variables: {input: {title:, description:, teamId: ENV['LINEAR_TEAM_ID']}}})
    end

    def tool_description
      'Linear is our task management tool. It allows you to create tasks for our team members'
    end
  end
end
