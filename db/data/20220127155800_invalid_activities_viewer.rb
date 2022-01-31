invalid_activities = []

Activity.find_each do |a|
  # a.touch
  # a.validate
  # warn "#{a} changed" if a.dirty?
  unless a.valid?
    warn "#{a.id}: #{a.title} invalid, #{a.errors.full_messages}"
    a.errors.each do |error|
      warn "#{error.attribute}, #{error.type}"
    end
    invalid_activities << a
  end

  # a.save(validate: false)
end

puts "#{invalid_activities.count} invalid_activities"
