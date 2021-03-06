class CreateChapters < ActiveRecord::Migration[5.0]
  def change
    if table_exists?(:chapters)
      drop_table(:chapters)
    end

    create_table :chapters do |t|
      t.references :book, foreign_key: true
      t.string :name
      t.string :url
      t.string :checksum

      t.timestamps
    end
  end
end
