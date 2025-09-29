class AddWebsiteJobTakeTraineesProposeWorkshopAndProposeSummerJobToCompany < ActiveRecord::Migration[7.0]
  def change
    change_table :companies do |t|
      t.string :website
      t.string :job
      t.boolean :take_trainee, default: false
      t.boolean :propose_workshop, default: false
      t.boolean :propose_summer_job, default: false
    end
  end
end
