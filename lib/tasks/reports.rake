namespace :reports do
  desc "Upload a single approved report to private S3 bucket"
  task :upload_to_s3, [:requester_id, :report_id] => :environment do |_, args|
    report_id = args[:report_id]
    requester_id = args[:requester_id]

    report = Report.find(report_id)
    uploader = User.find(requester_id)

    abort "Report #{report.id} has not been approved" unless report.approved?
    unless report.financial_year.present? && report.financial_quarter.present?
      abort "Report #{report.id} has no financial year or quarter"
    end
    abort "Report #{report.id} not found" if report.nil?
    abort "User with id #{requester_id} not found" if uploader.nil?

    sync_approved_at_with_updated_at(report)

    puts "Queueing CSV upload for report with ID #{report.id}"
    ReportExportUploaderJob.perform_later(requester_id: requester_id, report_id: report_id)
    puts "Upload queued"
  end

  desc "Upload all approved reports for all reporting organisations to private S3 bucket"
  task :upload_all_approved_reports_to_s3, [:requester_id] => :environment do |_, args|
    requester_id = args[:requester_id]
    uploader = User.find(requester_id)

    abort "User with id #{requester_id} not found" if uploader.nil?

    Organisation.reporters.each do |organisation|
      puts "Queueing CSV upload for organisation #{organisation.name}"
      non_uploaded_reports =
        organisation
          .reports
          .approved
          .where(export_filename: nil)
          .where.not("financial_year IS NULL OR financial_quarter IS NULL")

      non_uploaded_reports.each do |report|
        sync_approved_at_with_updated_at(report)

        ReportExportUploaderJob.perform_later(requester_id: uploader.id, report_id: report.id)
        print "."
      end
      puts "Uploads queued for organisation"
    end
  end

  def sync_approved_at_with_updated_at(report)
    return unless report.approved_at.nil?

    report.approved_at = report.updated_at
    report.save!
  end
end
