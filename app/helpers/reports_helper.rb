module ReportsHelper

  BLOCKS = ['1-FUND', '2-BLHD', '3-SBM', '4-CPR', '5-HODI', '6-NSF', '7-DEVH']

  def average_summary(summary_data, user)
    student_hash = {}
    student_hash.store('Student', user.full_name)
    student_hash.store('Email', user.email)
    total_score = 0.0
    average = 0.0

    BLOCKS.each do |block|
      found_block = summary_data.select{|s| s['course_code'] if s['course_code'] == block}
      if !found_block.empty?
        student_hash.store(found_block.first['course_code'] + ' Summary', found_block.first['average'].to_f)
        total_score += found_block.first['average'].to_f
      else
        student_hash.store(block + ' Summary', 0.0)
      end
    end

    no_of_blocks = summary_data.count
    average = total_score/7.0 #if no_of_blocks != 0
    student_hash.store('Cumulative FoM Average', average.round(2))
    return student_hash
  end

  def hf_get_ranking(users)
    data_array = []
    data_hash = {}
    users.each do |user|
      if user.username != 'bettybogus'
        summary_data = FomExam.execute_sql('select id, user_id, course_code, summary_comp1, summary_comp2a, summary_comp2b,
                        summary_comp3, summary_comp4, summary_comp5a, summary_comp5b,
                        ROUND((SUMMARY_COMP1+SUMMARY_COMP2A+SUMMARY_COMP2B+SUMMARY_COMP3+SUMMARY_COMP4+SUMMARY_COMP5A+SUMMARY_COMP5B)/7::numeric,2) AS Average
                        from fom_exams where user_id=#{user.id} order by course_code').to_a

          data_hash = average_summary(summary_data, user)
          data_array.push data_hash
      end
    end
    #data_array = data_array.sort_by{ |d| d['Cumulative FoM Average']}.reverse!
    # to sort the average in descending order - done in jquery using dataTables features
    return data_array
  end

  def hf_get_mspe_data (permission_group_id)
    permission_group_title = PermissionGroup.find(permission_group_id.to_i).title.split(' ').last.gsub(/[()]/, '').downcase

    # query = 'SELECT student_uid, user_id, users.permission_group_id, users.full_name, competencies.email, ' +
    #   'course_id, course_name, final_grade, start_date, end_date, submit_date, evaluator, ' +
    #   'prof_concerns, comm_prof_concerns, overall_summ_comm_perf, add_comm_on_perform, mspe, clinic_exp_comment ' +
    # 	'FROM public.competencies, #{permssion_group_title}_mspes, users ' +
    # 	'where ' +
    # 	'course_name not like '%FoM%' and course_name not like '%JCON%' and ' +
    # 	'course_name not like '%TRAN%' and course_name not like '%PREC 724%' and ' +
    # 	'course_name not like '%SCHI%' and course_name not like '%CPX 702%' and ' +
    # 	'course_name not like '%FAMP 705SD%' and course_name not like '%GMED 705AB%' and ' +
    # 	'course_name not like '%IMEDMINF 705B%' and course_name not like '%MULT 705A%' and ' +
    # 	'course_name not like '%MULT 705C%' and course_name not like '%MULT 705D%' and ' +
    # 	'course_name not like '%MULT 705TI%' and course_name not like '%709Z%' and ' +
    # 	'users.id = competencies.user_id and ' +
    # 	'#{permssion_group_title}_mspes.email = users.email ' +
    # 	'order by users.full_name, competencies.start_date'

    query = 'SELECT student_uid, user_id, users.permission_group_id, users.full_name, competencies.email, ' +
      'course_id, course_name, final_grade, start_date, end_date, submit_date, evaluator, ' +
      'prof_concerns, comm_prof_concerns, overall_summ_comm_perf, add_comm_on_perform, mspe, clinic_exp_comment ' +
    	"FROM public.competencies, users, #{permission_group_title}_mspes " +
    	'where ' +
      	# 'competencies.course_name not like ' + "'%FoM%'" + ' and competencies.course_name not like ' + "'JCON%'" + ' and ' +
      	# 'course_name not like '%TRAN%' and course_name not like '%PREC 724%' and ' +
      	# 'course_name not like '%SCHI%' and course_name not like '%CPX 702%' and ' +
      	# 'course_name not like '%FAMP 705SD%' and course_name not like '%GMED 705AB%' and ' +
      	# 'course_name not like '%IMEDMINF 705B%' and course_name not like '%MULT 705A%' and ' +
      	# 'course_name not like '%MULT 705C%' and course_name not like '%MULT 705D%' and ' +
      	# 'course_name not like '%MULT 705TI%' and course_name not like '%709Z%' and ' +
      'users.id = competencies.user_id and ' +
      "#{permission_group_title}_mspes.email = users.email " +
      'order by users.full_name, competencies.start_date'

    mspe_data = Competency.execute_sql(query).to_a


  return mspe_data

  end

  def hf_cohorts_comp_graph(comp_class_means)
    selected_categories = comp_class_means.first.last.keys
    height = 600
    title =  'Competency By Cohort(s) Graph' #+ '<br ><b>' + '(n = #{tot_count})' + '</b>'

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
      comp_class_means.keys.each do |key|
          f.series(type: 'column', name: key, yAxis: 0, data: comp_class_means['#{key}'].values)
      end

      # ['#FA6735', '#3F0E82', '#1DA877', '#EF4E49']
      # f.colors(['#4572A7',
      #           '#AA4643',
      #           '#89A54E',
      #           '#80699B',
      #           '#3D96AE',
      #           '#DB843D',
      #           '#92A8CD',
      #           '#A47D7C',
      #           '#B5CA92'
      #           ])

      f.yAxis [
         { min: 0, max: 100,
           tickInterval: 25,
           title: {text: '<b>Competency (%) </b>', margin: 20}
         }
      ]
      f.plot_options(
        pie: {
            dataLabels: {
                enabled: true,
                crop: false,
                format: '<b>{point.name}</b>:<br>{point.percentage:.1f} %<br>value: {point.y}'
            }
        },
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
                defaultSeriesType: 'column',
                width: 1800, height: height,
                plotBackgroundImage: ''
              })
    end

    return chart

  end


end
