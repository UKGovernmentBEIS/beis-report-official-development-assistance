ACTIVITY_WITH_CONTROL_CODE = "d7d98613-ed06-49ae-bb4f-8f6b5c28bcae"

# Activity.joins(:organisation).includes(:organisation).each do |a|
# Activity.find_each do |a|
a = Activity.find(ACTIVITY_WITH_CONTROL_CODE)
a.valid? #  this will call the before_validation hook which removes control codes
if a.changed?
  warn "#{a.id}: '#{a.title}' was changed: #{a.changed}"
  a.save(validate: false)
end
