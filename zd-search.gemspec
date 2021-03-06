Gem::Specification.new do |s|
    s.name = 'zd-search'
    s.version = '0.1.0'
    s.licenses = ['MIT']
    s.summary = 'A simple application to query Zendesk data from JSON files'
    s.authors = ['KJ Tsanaktsidis']
    s.email = 'kjtsanaktsidis@gmai..com'

    s.executables = 'zd-search'
    s.files = Dir['bin/*'] + Dir['lib/**/*.rb'] + Dir['spec/**/*.rb']

    s.add_dependency('trollop', '~> 2')
    s.add_dependency('activesupport', '~> 5')
end
