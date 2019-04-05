module EpaMastersHelper

  def create_epa_masters (selected_user_id)
    for i in 1..13 do
      EpaMaster.where(user_id: selected_user_id, epa: "EPA#{i}").first_or_create do |epa|
        epa.user_id = selected_user_id
        epa.epa = "EPA#{i}"
      end
    end
  end

  def get_review_date (rec)
    if rec.status3 == "Yes"
      return {rec.epa => hf_format_date(rec.review_date3)}
    elsif rec.status2 == "Yes"
      return {rec.epa => hf_format_date(rec.review_date2)}
    elsif rec.status1 == "Yes"
      return {rec.epa => hf_format_date(rec.review_date1)}
    else
      return {rec.epa => ""}
    end
  end

  def hf_get_epa_master_badges(selected_user_id)
    epa_badges = []
    review_date_array = []
    badged = {}
    review_date = {}
    selected_recs = EpaMaster.where(user_id: selected_user_id).order(:id)
    if selected_recs.length < 13
      create_epa_masters (selected_user_id)
      selected_recs = EpaMaster.where(user_id: selected_user_id).order(:id)
    end
    selected_recs.each do |rec|
      badged = {rec.epa => "epa/#{rec.epa}.png"}
      if (rec.status1.to_s + rec.status2.to_s + rec.status3.to_s).include? "Yes"
        review_date = get_review_date(rec)
      else
        review_date = {rec.epa => ""}
        #badged = {rec.epa => "epa/not_badge_#{rec.epa}.png"}
      end
      review_date_array.push review_date
      epa_badges.push badged
    end

    return epa_badges, review_date_array
  end

  def hf_format_date (in_date)
    unless in_date.nil?
      in_date = in_date.strftime("%m/%d/%Y")
    end
  end

  def hf_count_not_badged (in_hash)
    return in_hash.select{|k| k.first.second.include? "not" }.count
  end

  def hf_get_entrustment_members
    json ||= File.read("#{Rails.root}/public/entrustment_members.json")
    entrustment_members = JSON.parse(json).values.flatten.sort
    return entrustment_members
  end
end
