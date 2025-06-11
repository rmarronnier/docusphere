class AddQueryToSearchQueries < ActiveRecord::Migration[7.1]
  def change
    add_column :search_queries, :query, :string
    add_index :search_queries, :query
  end
end