class Schedule < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :room, optional: true

  enum description: { laboratory: 0, lecture: 1 }
  enum day: { Sunday: 0, Monday: 1, Tuesday: 2, Wednesday: 3, Thursday: 4, Friday: 5, Saturday: 6}
  enum semester: { first_sem: 0, second_sem: 1 }
  enum year_level: { first_year: 1, second_year: 2, third_year: 3, fourth_year: 4 }
  enum remarks: { archived: 0, restored: 1 }

  validates :subject, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :room_id, presence: true, numericality: { only_integer: true }
  validates :semester, presence: true

  validate :no_overlapping_schedule

  private

  def no_overlapping_schedule
    return if start_time.blank? || end_time.blank? || day.blank? || room_id.blank?

    overlapping = Schedule.where(day: day, room_id: room_id, semester: semester, school_year: school_year)
                          .where.not(id: id)
                          .select do |other|
      # Convert both times to seconds since midnight for comparison
      my_start = start_time.seconds_since_midnight
      my_end = end_time.seconds_since_midnight
      other_start = other.start_time.seconds_since_midnight
      other_end = other.end_time.seconds_since_midnight

      my_start < other_end && my_end > other_start
    end

    if overlapping.any?
      errors.add(:base, "Schedule overlaps with another schedule in the same room, day, and time.")
    end
  end

end
