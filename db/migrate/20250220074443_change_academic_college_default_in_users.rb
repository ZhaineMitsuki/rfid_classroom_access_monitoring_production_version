class ChangeAcademicCollegeDefaultInUsers < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :academic_college, from: 0, to: nil
    change_column_null :users, :academic_college, true
  end
end