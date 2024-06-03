
after_initialize do
  module ::DiscoursePrivateBanAppeals
    class Engine < ::Rails::Engine
      engine_name "discourse_private_ban_appeals"
      isolate_namespace DiscoursePrivateBanAppeals
    end
  end

  require_dependency 'topic_creator'
  class ::TopicCreator
    alias_method :original_create, :create

    def create
      result = original_create
      category_id = @opts[:category]
      category = Category.find_by(id: category_id)

      if category && category.name == "Ban Appeals"
        # Set the topic as private
        result.topic.update_columns(archetype: Archetype.private_message)
        TopicAllowedUser.create!(topic_id: result.topic.id, user_id: result.topic.user_id)

        # Add admins and moderators to the allowed users
        Group[:admins].users.each do |user|
          TopicAllowedUser.find_or_create_by!(topic_id: result.topic.id, user_id: user.id)
        end

        Group[:moderators].users.each do |user|
          TopicAllowedUser.find_or_create_by!(topic_id: result.topic.id, user_id: user.id)
        end
      end

      result
    end
  end
end
