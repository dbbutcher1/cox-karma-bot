class CreateSlackChannels < ActiveRecord::Migration[5.1]
  def change
    create_table :slack_channels do |t|
      t.string :name

      t.timestamps
    end
  end
end
