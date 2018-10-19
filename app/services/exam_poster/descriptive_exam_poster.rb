module ExamPoster
  class DescriptiveExamPoster < Base

    private

    def generate_requests
      post_by_step.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, descriptive_exam|
          self.requests << {
            etapa: @step.to_number,
            resource: 'pareceres-por-etapa-geral',
            pareceres: {
              classroom_id => {
                student_id => descriptive_exam
              }
            }
          }
        end
      end

      post_by_year.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, descriptive_exam|
          self.requests << {
            resource: 'pareceres-anual-geral',
            pareceres: {
              classroom_id => {
                student_id => descriptive_exam
              }
            }
          }
        end
      end

      post_by_year_and_discipline.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, student_descriptive_exam|
          student_descriptive_exam.each do |discipline_id, discipline_descriptive_exam|
            self.requests << {
              resource: 'pareceres-anual-por-componente',
              pareceres: {
                classroom_id => {
                  student_id => {
                    discipline_id => discipline_descriptive_exam
                  }
                }
              }
            }
          end
        end
      end

      post_by_step_and_discipline.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, student_descriptive_exam|
          student_descriptive_exam.each do |discipline_id, discipline_descriptive_exam|
            self.requests << {
              etapa: @step.to_number,
              resource: 'pareceres-por-etapa-e-componente',
              pareceres: {
                classroom_id => {
                  student_id => {
                    discipline_id => discipline_descriptive_exam
                  }
                }
              }
            }
          end
        end
      end
    end

    protected

    def post_by_step
      descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      teacher.classrooms.uniq.each do |classroom|
        @step = get_step(classroom)

        next if classroom.unity_id != @step.school_calendar.unity_id
        next unless step_exists_for_classroom?(classroom)

        if classroom.calendar
          exams = DescriptiveExamStudent.includes(:student)
                                        .by_classroom_and_classroom_step(classroom, @step.id)
                                        .ordered
        else
          exams = DescriptiveExamStudent.includes(:student)
                                        .by_classroom_and_step(classroom, @step.id)
                                        .ordered
        end

        exams.each do |exam|
          next unless valid_opinion_type?(exam.student.uses_differentiated_exam_rule, OpinionTypes::BY_STEP, classroom.exam_rule)
          descriptive_exams[classroom.api_code][exam.student.api_code]["valor"] = exam.value
        end
      end

      descriptive_exams
    end

    def post_by_year
      descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      teacher.classrooms.uniq.each do |classroom|
        next if classroom.unity_id != @step.school_calendar.unity_id

        exams = DescriptiveExamStudent.by_classroom(classroom).ordered
        exams.each do |exam|
          next unless valid_opinion_type?(exam.student.uses_differentiated_exam_rule, OpinionTypes::BY_YEAR, classroom.exam_rule)
          descriptive_exams[classroom.api_code][exam.student.api_code]["valor"] = exam.value
        end
      end

      descriptive_exams
    end

    def post_by_year_and_discipline
      descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        classroom = teacher_discipline_classroom.classroom
        discipline = teacher_discipline_classroom.discipline

        next if classroom.unity_id != @step.school_calendar.unity_id

        exams = DescriptiveExamStudent.by_classroom_and_discipline(classroom, discipline).ordered
        exams.each do |exam|
          next unless valid_opinion_type?(exam.student.uses_differentiated_exam_rule, OpinionTypes::BY_YEAR_AND_DISCIPLINE, classroom.exam_rule)
          descriptive_exams[classroom.api_code][exam.student.api_code][discipline.api_code]["valor"] = exam.value
        end
      end

      descriptive_exams
    end

    def post_by_step_and_discipline
      descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        classroom = teacher_discipline_classroom.classroom
        discipline = teacher_discipline_classroom.discipline

        next if classroom.unity_id != @step.school_calendar.unity_id
        next unless step_exists_for_classroom?(classroom)

        if classroom.calendar
          exams = DescriptiveExamStudent.by_classroom_discipline_and_classroom_step(classroom, discipline, @step.id).ordered
        else
          exams = DescriptiveExamStudent.by_classroom_discipline_and_step(classroom, discipline, @step.id).ordered
        end

        exams.each do |exam|
          next unless valid_opinion_type?(exam.student.uses_differentiated_exam_rule, OpinionTypes::BY_STEP_AND_DISCIPLINE, classroom.exam_rule)
          descriptive_exams[classroom.api_code][exam.student.api_code][discipline.api_code]["valor"] = exam.value
        end
      end

      descriptive_exams
    end
    def valid_opinion_type?(differentiated, opinion_type, exam_rule)
      exam_rule = (exam_rule.differentiated_exam_rule || exam_rule) if differentiated
      exam_rule.opinion_type == opinion_type
    end
  end
end
