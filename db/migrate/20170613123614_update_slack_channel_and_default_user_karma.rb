class UpdateSlackChannelAndDefaultUserKarma < ActiveRecord::Migration[5.1]
  def change
    change_column :slack_users, :karma, :integer, default: 0

    change_table :slack_channels do |t|
      t.string :slack_id
    end
  end
end
