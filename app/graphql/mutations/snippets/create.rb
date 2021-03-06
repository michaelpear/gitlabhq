# frozen_string_literal: true

module Mutations
  module Snippets
    class Create < BaseMutation
      include ResolvesProject

      graphql_name 'CreateSnippet'

      field :snippet,
            Types::SnippetType,
            null: true,
            description: 'The snippet after mutation'

      argument :title, GraphQL::STRING_TYPE,
               required: true,
               description: 'Title of the snippet'

      argument :file_name, GraphQL::STRING_TYPE,
               required: false,
               description: 'File name of the snippet'

      argument :content, GraphQL::STRING_TYPE,
               required: false,
               description: 'Content of the snippet'

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: 'Description of the snippet'

      argument :visibility_level, Types::VisibilityLevelsEnum,
               description: 'The visibility level of the snippet',
               required: true

      argument :project_path, GraphQL::ID_TYPE,
               required: false,
               description: 'The project full path the snippet is associated with'

      argument :uploaded_files, [GraphQL::STRING_TYPE],
               required: false,
               description: 'The paths to files uploaded in the snippet description'

      argument :files, [Types::Snippets::FileInputType],
               description: "The snippet files to create",
               required: false

      def resolve(args)
        project_path = args.delete(:project_path)

        if project_path.present?
          project = find_project!(project_path: project_path)
        elsif !can_create_personal_snippet?
          raise_resource_not_available_error!
        end

        service_response = ::Snippets::CreateService.new(project,
                                                         context[:current_user],
                                                         create_params(args)).execute

        snippet = service_response.payload[:snippet]

        {
          snippet: service_response.success? ? snippet : nil,
          errors: errors_on_object(snippet)
        }
      end

      private

      def find_project!(project_path:)
        authorized_find!(full_path: project_path)
      end

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end

      def authorized_resource?(project)
        Ability.allowed?(context[:current_user], :create_snippet, project)
      end

      def can_create_personal_snippet?
        Ability.allowed?(context[:current_user], :create_snippet)
      end

      def create_params(args)
        args.tap do |create_args|
          # We need to rename `files` into `snippet_files` because
          # it's the expected key param
          create_args[:snippet_files] = create_args.delete(:files)&.map(&:to_h)

          # We need to rename `uploaded_files` into `files` because
          # it's the expected key param
          create_args[:files] = create_args.delete(:uploaded_files)
        end
      end
    end
  end
end
