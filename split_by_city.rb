# split vw files by city

cities = ['richmond', 'oakland', 'chicago', 'new_haven']
sets   = ['train', 'valid', 'trainvalid', 'test']
models = ['comments', 'views', 'votes']
vw_dir = 'out/vw'

cities.each { |city|
  sets.each { |set|
    models.each { |model|
      orig = "#{vw_dir}/#{model}_#{set}"
      new  = "#{orig}_#{city}"
      cmd1 = "grep '|city #{city} |' #{orig}.vw > #{new}.vw"
      cmd2 = "cut -d\\  -f 1 < #{new}.vw > #{new}.gt"
      puts cmd1
      system cmd1
      puts cmd2
      system cmd2
    }
  }
}

