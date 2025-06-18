class User < ApplicationRecord
  has_many :cards, dependent: :destroy
  has_many :schedules, dependent: :destroy
  has_many :time_tracks, dependent: :destroy

  before_destroy :destroy_archived_associations

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  enum role: { admin: 0, professor: 1, super_admin: 2 }
  enum academic_college: { CIE: 0, COE: 1, CLA: 2, COS: 3, CAFA: 4, CIT: 5 }
  enum status: { inactive: 0, active: 1 }
  enum remarks: { archived: 0, restored: 1 }

  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :academic_college, presence: true
  validates :email, presence: true

  def destroy_archived_associations
    cards.where(remarks: 'archived').destroy_all
    schedules.where(remarks: 'archived').destroy_all
    time_tracks.where(remarks: 'archived').destroy_all
  end
end
