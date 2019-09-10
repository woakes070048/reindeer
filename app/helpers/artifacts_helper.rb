module ArtifactsHelper

  def hf_get_fom_artifacts (pk, artifact_title, artifact_content)
    selected_user = User.find_by(email: pk)
    if selected_user.nil?
      return nil,0
    else
      no_docs = 0
      artifacts_student = Artifact.where(user_id: selected_user.id)
      fom_docs = artifacts_student.select{|a| a.title == artifact_title and a.content == artifact_content}
      fom_docs.each do |doc|
        no_docs = no_docs + doc.documents.count
      end
      #@shelf_artifacts = artifacts_student.select{|a| a.content == "Shelf Exams"}

      return artifacts_student, no_docs, fom_docs
    end
  end

end
