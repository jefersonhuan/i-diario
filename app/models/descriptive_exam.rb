class DescriptiveExam < ActiveRecord::Base
  include Audit
  include Stepable

  acts_as_copy_target

  # acts_as_paranoid

  audited
  has_associated_audits
  before_save :mark_students_for_removal

  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar_step, -> { unscope(where: :active) }
  belongs_to :school_calendar_classroom_step, -> { unscope(where: :active) }

  has_many :students, class_name: 'DescriptiveExamStudent', dependent: :destroy

  accepts_nested_attributes_for :students

  delegate :unity, to: :classroom, allow_nil: true

  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }

  validates :unity, presence: true
  validates :opinion_type, presence: true
  validates :discipline_id, presence: true, if: :should_validate_presence_of_discipline

  def mark_students_for_removal
    students.each do |student|
      student.mark_for_destruction if student.value.blank?
    end
  end

  private

  def should_validate_presence_of_discipline
    return unless opinion_type

    [OpinionTypes::BY_STEP_AND_DISCIPLINE, OpinionTypes::BY_YEAR_AND_DISCIPLINE].include?(opinion_type)
  end
end
