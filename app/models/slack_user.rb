class SlackUser < ApplicationRecord
  has_and_belongs_to_many :slack_channels

  alias_method :channels, :slack_channels
end
