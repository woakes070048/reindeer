class EventMailer < ApplicationMailer

  SENDER_SIGN = "Thanks!\n" +
                "OASIS Team\n" +
                "Erika Chomina Lenford\n" +
                "OASIS Program Manager\n" +
                "OHSU School of Medicine|UME\n" +
                "chomina@ohsu.edu"

  def notify_student (meeting, method)

      @event_mailer = Event.find(meeting.event_id)
      @meeting_mailer = meeting

      student_email = meeting.user.email # student email
      first_name = meeting.user.full_name.split(", ").last
      cc_email = Advisor.find_by(id: meeting.advisor_id).email  # advisor email
      username = cc_email.split('@').first
      emails = []
      if student_email == 'bettybogus@ohsu.edu'
        student_email = 'chungp@ohsu.edu'
      end
      emails << student_email
      emails << cc_email
      if method == "Create"
        subject_msg = "New Appointment with #{@event_mailer.description} on #{@event_mailer.start_date.strftime("%m/%d/%Y %I:%M %p - %A")}"

        @cal_body_msg = "The appointment has been created in REDEI.  Please be prepared to meet with " +
                     @event_mailer.description + " on " + @event_mailer.start_date.strftime("%m/%d/%Y %I:%M %p - %A") +  ".\\n\\n" +
                     "Here is the advisor personal WebEx link: \\n" +
                     "https://ohsu.webex.com/meet/#{username}\\n\\n\\n"

       @body_msg = "The appointment has been created in REDEI.  Please be prepared to meet with " +
                    @event_mailer.description + " on " + @event_mailer.start_date.strftime("%m/%d/%Y %I:%M %p - %A") +  ".<br><br>" +
                    "Here is the advisor personal WebEx link: <br>" +
                    "https://ohsu.webex.com/meet/#{username}<br><br><br>"

        log_emails(emails, "New Appointment: ", @event_mailer, subject_msg)
      elsif method == 'Cancel'
        subject_msg = "Canceled:Your Appointment with #{@event_mailer.description} on #{@event_mailer.start_date.strftime("%m/%d/%Y %I:%M %p - %A")} has been canceled."
        @body_msg =  "Your appointment with " + @event_mailer.description + " on " + @event_mailer.start_date.strftime("%m/%d/%Y %I:%M %p - %A") + " has been canceled.\n\n"
        @cal_body_msg = @body_msg
        log_emails(emails, "Canceled Appointment: ", @event_mailer, subject_msg)
      end

       ical = Icalendar::Calendar.new
       e = Icalendar::Event.new
       e.dtstart = @event_mailer.start_date #DateTime.now.utc
       #e.start.icalendar_tzid="UTC" # set timezone as "UTC"
       e.dtend = @event_mailer.end_date #(DateTime.now + 1.day).utc
       #e.end.icalendar_tzid="UTC"
       e.organizer = student_email
       e.uid = "MeetingReques#{meeting.id}"
       e.summary = subject_msg
       e.description = "Hello " + first_name + ",\n\n" + @cal_body_msg + SENDER_SIGN #{}"Testing icalendar!"
       ical.add_event(e)
       #ical.publish
       ical.to_ical
       attachments['calendar.ics'] = ical.to_ical
       mail(to: emails, from: "chomina@ohsu.edu", subject: subject_msg)

       # mail(to: emails, from: "chomina@ohsu.edu", subject: subject_msg, mime_version: '1.0',
       #   content_type: 'text/calendar; method=REQUEST; charset=UTF-8; component=VEVENT',
       #   body: ical.to_ical + "\nTesting...",
       #   content_disposition: "attachment; filename=calendar.ics")


  end

  def notify_student_advisor_appt_cancel (meeting)
      @event_mailer = Event.find(meeting.event_id)
      @meeting_mailer = meeting
      student_email = meeting.user.email # student email
      cc_email = Advisor.find_by(id: meeting.advisor_id).email  # advisor email
      emails = []

      emails << student_email
      emails << cc_email
      if student_email == 'bettybogus@ohsu.edu'
        student_email = 'chungp@ohsu.edu'
      end
      subject_msg = "Your Appointment with #{@event_mailer.description} on #{@event_mailer.start_date.strftime("%m/%d/%Y %I:%M %p - %A")} has been canceled."

      log_emails(emails, "Cancel Appointment: ", @event_mailer, @meeting_mailer)

      mail(to: emails, from: "chomina@ohsu.edu", subject: subject_msg)

  end

  def log_emails (to_emails, message, event_mailer, subject_msg)
    filename = "#{Rails.root}/log/email_notifications.log"
    File.open(filename,"a") do |f|
      f.write("===========================================================================\n")
      f.write(message + "\n")
      f.write("Emails sent on " + Time.now.strftime("%d/%m/%Y %H:%M") + "\n")
      f.write("Emails: " + to_emails.inspect + "\n")
      f.write("subject: " + subject_msg + "\n")
      f.write("===========================================================================\n")
    end
  end

end
