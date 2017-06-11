class SlackChannel < ApplicationRecord
  has_and_belongs_to_many :slack_users

  alias_method :users, :slack_users
end
