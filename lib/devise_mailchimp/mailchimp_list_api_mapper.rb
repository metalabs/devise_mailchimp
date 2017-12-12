require 'mailchimp_api_v3'

module Devise
  module Models
    module Mailchimp
      class MailchimpListApiMapper

        # craete a new ApiMapper with the provided API key
        def initialize(api_key)
          @api_key = api_key
        end

        def name_to_list(list_name)
          list = mailchimp.lists.find_by name: list_name
        end

        def language_to_interest_id(language, list)
          list.interest_categories.first.interests.where(name: language).first.id
        end

        # subscribes the user to the named mailing list(s).  list_names can be the name of one list, or an array of
        # several.
        #
        # NOTE: Do not use this method unless the user has opted in.
        def subscribe_to_lists(list_names, email, options, language = "en-GB", latitude = nil, longitude = nil)
          list_names = [list_names] unless list_names.is_a?(Array)
          list_names.each do |list_name|
            list = name_to_list(list_name)
            member = list.members(email)
            if member.present? 
              if member.status == "subscribed"
                member.update(
                  language: language[0,2],
                  merge_fields: options,
                  interests: {language_to_interest_id(language, list) => true},
                  location: {latitude: latitude, longitude: longitude}
                )
              end
            else
              list.members.create(
                email_address: email,
                status: "subscribed",
                language: language[0,2],
                merge_fields: options,
                interests: {language_to_interest_id(language, list) => true},
                location: {latitude: latitude, longitude: longitude}
              )
            end
          end
        end

        # updates the user to the named mailing list(s).  list_names can be the name of one list, or an array of
        # several.
        #
        def update_to_lists_if_member_already_exist(list_names, email, options, language = "en-GB", latitude = nil, longitude = nil)
          list_names = [list_names] unless list_names.is_a?(Array)
          list_names.each do |list_name|
            list = name_to_list(list_name)
            member = list.members(email)
            if member.present? && member.status == "subscribed"
              member.update(
                language: language[0,2],
                merge_fields: options,
                interests: {language_to_interest_id(language, list) => true},
                location: {latitude: latitude, longitude: longitude}
              )
            end
          end
        end

        # unsubscribe the user from the named mailing list(s).  list_names can be the name of one list, or an array of
        # several.
        def unsubscribe_from_lists(list_names, email)
          list_names = [list_names] unless list_names.is_a?(Array)
          list_names.each do |list_name|
            list = name_to_list(list_name)
            list.members(email).update(
              status: "unsubscribed"
            )
          end
        end

        private

        # the mailchimp helper
        def mailchimp
          ::Mailchimp.connect(@api_key)
        end
      end
    end
  end
end
