class CreateTestingStructure < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name, :so, :gui, :other, :language, :kind
      t.string :status, :default => :active
      t.string :limited, :limit => 10
      t.string :karma, :limit => 5
      t.boolean :sex
      t.boolean :public
      t.boolean :cool
      t.string :role
      t.string :country, :default => "pt"
      t.string :some_attr  # used in name collision tests
    end
    create_table :user_skills do |t|
      t.references :user
      t.string :kind
    end
    create_table :user_extras do |t|
      t.references :user
      t.string :key, :null => false
    end
    create_table :permissions do |t|
      t.string  :name, :null => false
      t.string  :kind, :null => false
      t.integer :lvl,  :null => false
    end
  end
end
