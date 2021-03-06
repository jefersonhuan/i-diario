require 'rails_helper'

RSpec.describe AbsenceCountService, type: :service do
  let(:student) { create(:student) }
  let(:classroom) { create(:classroom, :current, period: '4') }
  let(:discipline) { create(:discipline) }
  let(:school_calendar) { create(:school_calendar_with_one_step, :current, unity: classroom.unity) }
  let(:start_date) { school_calendar.steps.first.start_at }
  let(:end_date) { school_calendar.steps.first.end_at }

  describe '#count' do
    context 'with general presence' do
      subject do
        described_class.new(student, classroom, start_date, end_date)
      end
      context 'when a student is absent in both periods' do
        it 'count as only one absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1), false),
             create_daily_frequency_student(create_daily_frequency(2), false)]
          )

          expect(subject.count).to eq(1)
        end
      end

      context 'when a student is present in at least one period' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1), true),
             create_daily_frequency_student(create_daily_frequency(2), false)]
          )

          expect(subject.count).to eq(0)
        end
      end

      context 'when a student is present in both periods' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1), true),
             create_daily_frequency_student(create_daily_frequency(2), true)]
          )

          expect(subject.count).to eq(0)
        end
      end
    end

    context 'with presence by components' do
      subject do
        described_class.new(student, classroom, start_date, end_date, discipline)
      end

      context 'when a student is absent in both periods for the same class number' do
        it 'does count only one absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1, discipline, 1), false),
             create_daily_frequency_student(create_daily_frequency(2, discipline, 1), false)]
          )

          expect(subject.count).to eq(1)
        end
      end

      context 'when a student is present in at least one period for the same class number' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1, discipline, 1), true),
             create_daily_frequency_student(create_daily_frequency(2, discipline, 1), false)]
          )

          expect(subject.count).to eq(0)
        end
      end

      context 'when a student is present in btoth periods for the same class number' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1, discipline, 1), true),
             create_daily_frequency_student(create_daily_frequency(2, discipline, 1), true)]
          )

          expect(subject.count).to eq(0)
        end
      end
    end
  end

  def create_daily_frequency(period, discipline = nil, class_number = nil)
    create(
      :daily_frequency,
      frequency_date: "04/01/#{school_calendar.year}",
      classroom: classroom,
      discipline: discipline,
      class_number: class_number,
      school_calendar: school_calendar,
      period: period
    )
  end

  def create_daily_frequency_student(daily_frequency, presence)
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency,
      present: presence
    )
  end
end
