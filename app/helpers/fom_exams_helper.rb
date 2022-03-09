module FomExamsHelper

COMPONENT_DESC = {'comp1_wk' => 'Component 1: Medical Knowledge (Weekly Tests/Quizzes)',
                  'comp2a_hss' => 'Component 2A: Clinical/Health Systems Science Skills Assessments',
                  'comp2b_bss' => 'Component 2B: Basic Science Skills Assessments',
                  'comp3_final' => 'Component 3: Final Block Exam',
                  'comp4_nbme' => 'Component 4: NBME Exam',
                  'comp5a_hss' => 'Component 5A: Clinical/Health Systems Science Skills Assessments',
                  'comp5b_bss' => 'Component 5B: Basic Science Skills Assessment',
                  'summary_comp' => 'Summary Data'
                }

BLOCKS = {  '1-FUND' => "Fundamentals",
            '2-BLHD' => "Blood & Host Defense",
            '3-SBM'  => "Skin, Bones & Musculature",
            "4-CPR"  => "Cardiopulmonary & Renal",
            "5-HODI" => "Hormones & Digestion",
            "6-NSF"  => "Nervous System & Function",
            "7-DEVH" => "Developing Human"

}

## Questin labels for formative feedback
LABELS = {
  "q1" => "Student Name",
  "q2" => "Facilitator Name",
  "q3" => "Please comment on any kudos you have for this student.",
  "q4" => "Please provide any comments on areas this student needs to work on.",
  "q5" => "Chief concern noted either before HPI or as part of introductory sentence, framed by the patient's most pertinent history.",
  "q6" => "The HPI starts with a clear patient introduction including patient's age, sex, and the chief complaint. The chief complaint is framed by their pertinent active medical problems, the reason for seeking care, and includes the time course.",
  "q7" => "Presents a focused physical exam. Begins with vitals, general appearance, and pertinent PE findings (no need to include non-pertinent normal findings).",
  "q8" => "H&P proposes either a diagnostic or therapeutic plan."
}
#-------------------------------------------------------------------------
# qualtric Question  --- Database # Question/fieldname
#   Q11                   Q3
#   Q12                   Q4
#   Q3                    Q5
#   Q13                   Q6
#-------------------------------------------------------------------------
LABELS2 = {
  "q1" => "Student Name",
  "q2" => "Facilitator Name",
  "q3" => "Regarding the student's history-taking during this patient encounter, please provide positive feedback and constructive suggestions for improvement.",
  "q4" => "Regarding the student's examination skills  during this patient encounter, please provide positive feedback and constructive suggestions for improvement.",
  "q5" => "Regarding the student's discussion skills during this patient encounter, please provide positive feedback and constructive suggestions for improvement.",
  "q6" => "Do you have any other comments or suggestions for this student? (optional)",
  "q7" => "",
  "q8" => ""
}


  def hf_get_block_desc(in_code)
    return BLOCKS[in_code]
  end

  def hf_component_desc(in_code)
    return COMPONENT_DESC[in_code]
  end

  def hf_formative_feedback_labels(in_q, label_code)
    if label_code == '_qs1'
      label = LABELS[in_q]
    elsif label_code == '_qs2'
      label = LABELS2[in_q]
    else
      return in_q
    end

     if label.nil?
       return in_q
     else
       return label
     end
  end

  def hf_check_failed_comp(comp, failed_comps, coaching_type)

    str_warning = ""
    return str_warning if coaching_type == "student"
    failed_comps.each do |fcomp|
      if fcomp.include? comp
        return '<div class="fa fa-exclamation-triangle" style="color:red"> </div>'
      end
    end
    return str_warning
  end

  def hf_scan_failed_score(hash_components)
    failed_comp = []
    comp_keys = FomExam.comp_keys
    hash_components.each do |comp|
      comp_keys.each do |comp_key|
        value = comp.map{|key, value| value if key.include? comp_key and value.to_d < 70.00}.compact
        if !value.empty?
          failed_comp.push comp_key
        end
      end
    end

    return failed_comp

  end

  def check_pass_fail(data_series)
    fail_hash = {}
    new_series = []
    data_series.each do |score|
      if (score < 70 and score != 0.0)
        fail_hash = {y: score, color: "#FF6D5A"}
        new_series.push fail_hash
      elsif score == 0.0
        fail_hash = {y: nil}
        new_series.push fail_hash
      else
        new_series.push score
      end
    end
    return new_series
  end

  def hf_check_label_file(attachment_id)
    filename = ActiveStorage::Attachment.find(attachment_id).filename.to_s
    if filename.downcase.include? 'label'
      csv_table = CSV.parse(ActiveStorage::Attachment.find(attachment_id).download, headers: true, col_sep: "\t")
      json_string = csv_table.map(&:to_h).to_json
      label_hash = JSON.parse(json_string)
      permission_group_id = label_hash.first["permission_group_id"]
      course_code = label_hash.first["course_code"]
      if !course_code.blank?
        FomLabel.where(permission_group_id: permission_group_id, course_code: course_code).first_or_create.update(labels: json_string)
        return true
      end
    else
      return false
    end
  end

  def hf_export_fom_block permission_group_id, course_code
    fom_label = FomLabel.where(permission_group_id: permission_group_id, course_code: course_code).first
    row_to_hash = JSON.parse(fom_label.labels).first  # fom_label.labels is a json object
    sql = "select users.full_name, "
    row_to_hash.each do |fieldname, val|  # build sql using form label record --> customized headers
      if fieldname != 'permission_group_id' and !val.nil?
        val = val.gsub(" ", "")
        sql += fieldname + ', '  #"#{key}, "
      end
    end
    sql = sql.delete_suffix(", ")
    results = FomExam.execute_sql(sql + " from fom_exams, users where users.id = fom_exams.user_id  and fom_exams.course_code = " + "'#{course_code}'" +
              " and fom_exams.permission_group_id=" + "#{permission_group_id} " + " order by users.full_name ASC").to_a

    return results
  end

  def hf_create_graph(component, class_data, avg_data,  categories)

    student_name = class_data.first["full_name"]  # processing student Alver
    student_series = class_data.first.drop(2)  # removed the first 2 items in array
    student_series = student_series.map{|d| d.second.to_s.to_f if d.first.include? component}.compact

    #student_series = student_series[0..-3].map{|s| s.second.to_f} # removed the last 2 items in array
    student_series = check_pass_fail(student_series)
    class_mean_series = avg_data.first.map{|s| s.second.to_s.to_d.truncate(2).to_f if s.first.include? component}.compact
    class_mean_series = check_pass_fail(class_mean_series)
    selected_categories = categories.map {|key, val| val if key.include? component}.compact
    height = 400

    title =  hf_component_desc(component) + '<br ><b>' + student_name + '</b>'

    chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: title)
      #f.subtitle(text: '<br /><h4>Student: <b>' + student_name + '</h4></b>')
      f.xAxis(categories: selected_categories,
        labels: {
              style:  {
                          fontWeight: 'bold',
                          color: '#000000'
                      }
                }
      )
      f.series(name: "Student", yAxis: 0, data: student_series)
      f.series(name: "Class Mean", yAxis: 0, data: class_mean_series)

      # ["#FA6735", "#3F0E82", "#1DA877", "#EF4E49"]
      f.colors(["#7EFF5E", "#6E92FF"])

      f.yAxis [
         { tickInterval: 20,
           title: {text: "<b>Score (%)</b>", margin: 20}
         }
      ]
      f.plot_options(
        column: {
            dataLabels: {
                enabled: true,
                crop: false,
                overflow: 'none'
            }
        },
        series: {
          cursor: 'pointer'
        }
      )
      f.legend(align: 'center', verticalAlign: 'bottom', y: 0, x: 0)
      #f.legend(align: 'right', verticalAlign: 'top', y: 75, x: -50, layout: 'vertical')
      f.chart({
                defaultSeriesType: "column",
                width: 1100, height: height,
                plotBorderWidth: 0,
                borderWidth: 0,
                plotShadow: false,
                borderColor: '',
                plotBackgroundImage: ''
              })
    end

    return chart
  end

end
