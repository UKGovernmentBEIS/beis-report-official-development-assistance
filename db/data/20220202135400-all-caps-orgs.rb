Organisation.find_each do |org|
  old_name = org.name.dup # we need this otherwise it *is* org.name, which we change, and hence changes
  org.name.upcase!
  org.name.squish!

  puts "[#{old_name}] became [#{org.name}]" if old_name != org.name
  org.save(validate: false)
end
