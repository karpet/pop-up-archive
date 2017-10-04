class MyMailer < ActionMailer::Base
  default to: ENV['MAILTO'], from: ENV['EMAIL_FROM'], template_path: ['base', 'mailer']

  def mailto(subject, body, to=nil)
    @body = body
    if to
      mail(subject: subject, to: to)
    else
      mail(subject: subject)
    end
  end

  def batch_report
    attachments['report.csv'] = { content: File.read("#{Rails.root}/db/completed_american_archive_AA1670L5.csv"), mime_type: "text/csv"}
    mail(to: 'anders@popuparchive.org', subject: "American Archive items for #{DateTime.now}", body: "report")
  end

  def usage_alert(subject, body, to=nil)
    @body = body
    mail(subject: subject, to: to)
  end

end
