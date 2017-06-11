class SlackChannelsUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :slack_channels_users, id: false do |t|
      t.belongs_to :slack_channel, index: true
      t.belongs_to :slack_user, index: true
    end
  end
end
