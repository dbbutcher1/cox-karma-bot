class CreateSlackUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :slack_users do |t|
      t.string :alias
      t.string :slack_id
      t.integer :karma

      t.timestamps
    end
  end
end
