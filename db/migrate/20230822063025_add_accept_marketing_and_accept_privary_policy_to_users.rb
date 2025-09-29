class AddAcceptMarketingAndAcceptPrivaryPolicyToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :accept_marketing, :boolean, default: false
    add_column :users, :accept_privacy_policy, :boolean, default: false
  end
end
