class MakeSchoolLevelSchoolIdOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :school_levels, :school_id, true
    
    say "Made school_levels.school_id nullable"
    say "School levels can now be created without a school (independent classes)"
    say "Teachers can create independent classes before transferring to schools"
  end
end
