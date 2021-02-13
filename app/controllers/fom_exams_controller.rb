class FomExamsController < ApplicationController

  protect_from_forgery prepend: true, with: :exception
  before_action :authenticate_user!

  include FomExamsHelper
  include ArtifactsHelper

  def index
    @artifacts = Artifact.where(user_id: params[:user_id])
  end

  def list_all_blocks
    @list_all_blocks = FomExam.distinct.pluck(:permission_group_id, :course_code).sort
    respond_to do |format|
      format.html
    end
  end

  def export_block
    if params[:permssion_group_id].present? and params[:course_code].present?
      @export_block = FomExam.includes(:user_only_fetch_email).where(permission_group_id: params[:permssion_group_id], course_code: params[:course_code])
      send_data @export_block.to_csv,  filename: 'export_block.csv', disposition: 'download'
    end
    respond_to do |format|
      format.html
    end
  end

  def process_csv
    # @artifacts.first.documents.first.download --> works
    if !hf_check_label_file(params[:attach_id])
      @log_results = FomExam.process_file(params[:attach_id])
    end

  end

  def send_alerts
    if params[:uniq_cohort].present?
      fom_label = FomLabel.last
      @user_ids = FomExam.where(permission_group_id: params[:uniq_cohort], course_code: fom_label.course_code).pluck(:user_id)
    elsif params[:email_message].present? #ajax
        @email_message = JSON.parse(params[:email_message])
        FomExamMailer.notify_student(@user_ids, @email_message).now
#byebug
    end

    respond_to do |format|
      format.js {render action: 'send_alerts', status: 200}
      format.html
    end

  end

  def display_fom

    if params[:sid].present?  #current_user.admin_or_higher?
      if params[:sid] == current_user.sid or current_user.coaching_type == 'dean' or
        current_user.coaching_type == 'coach' or current_user.coaching_type == 'admin'
       #permission_group_id  = 17 # cohort Med23
       @course_code = params[:course_code]  #session[:course_code]  #params[:course_code]


       @comp_keys = FomExam.comp_keys
       student  = User.find_by(sid: params[:sid])
       @student_email = student.email
       @student_full_name = student.full_name
       #@coach_info = student.cohort.nil? ? "Not Assigned" : student.cohort.title
       @block_desc = hf_get_block_desc(@course_code)
       @student_uid = student.sid

       @comp_exams, @comp_avg_exams,  @exam_headers = FomExam.exec_raw_sql(student.id, session[:attach_id], student.permission_group_id, @course_code )

       @failed_comps = hf_scan_failed_score(@comp_exams)
       block_code = @course_code.split("-").second  #course_code format '1-FUND', '2-BLHD', etc
       @artifacts_student_fom, @no_official_docs, @shelf_artifacts = hf_get_fom_artifacts(@student_email, "FoM", block_code)
     else
       @comp_keys = ' **** You NOT AUTHORIZED to view this account! ***'
     end
    end

    respond_to do |format|
      format.html
    end
  end

 private

end
