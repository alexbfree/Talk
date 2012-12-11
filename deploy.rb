#!/usr/bin/env ruby

require 'aws-sdk'
AWS.config access_key_id: ENV['S3_ACCESS_ID'], secret_access_key: ENV['S3_SECRET_KEY']
s3 = AWS::S3.new
bucket = s3.buckets['talk.snapshotserengeti.org']
prefix = ''

build = <<-BASH
rm -rf build
cp -R public pre_build_public
cp -RL public build_public
rm -rf public
mv build_public public
echo 'Building application...'
hem build
mv public build
mv pre_build_public public
BASH

timestamp = `date -u +%Y-%m-%d_%H-%M-%S`.chomp

compress = <<-BASH
echo 'Compressing...'

timestamp=#{ timestamp }

mv build/application.js "build/application-$timestamp.js"

./node_modules/clean-css/bin/cleancss build/application.css -o "build/application-$timestamp.css"
rm build/application.css
gzip -9 -c "build/application-$timestamp.js" > "build/application-$timestamp.js.gz"
gzip -9 -c "build/application-$timestamp.css" > "build/application-$timestamp.css.gz"
BASH

system build
system compress

index = File.read 'build/index.html'
index.gsub! 'application.js', "application-#{ timestamp }.js"
index.gsub! 'application.css', "application-#{ timestamp }.css"
File.open('build/index.html', 'w'){ |f| f.puts index }

app_js = File.read "build/application-#{ timestamp }.js"
File.open("build/application-#{ timestamp }.js", 'w'){ |f| f.puts app_js }

working_directory = File.expand_path Dir.pwd
Dir.chdir 'build'

to_upload = []

if ARGV[0] == 'quick'
  %w(js css html).each{ |ext| to_upload << Dir["**/*.#{ ext }*"] }
  to_upload.flatten!
else
  to_upload = Dir['**/*'].reject{ |path| File.directory? path }
end

to_upload.delete 'index.html'
total = to_upload.length

to_upload.each.with_index do |file, index|
  content_type = case File.extname(file)
  when '.html'
    'text/html'
  when '.js'
    'application/javascript'
  when '.css'
    'text/css'
  when '.gz'
    'application/x-gzip'
  when '.ico'
    'image/x-ico'
  else
    `file --mime-type -b #{ file }`.chomp
  end
  
  puts "#{ '%2d' % (index + 1) } / #{ '%2d' % (total + 1) }: Uploading #{ [prefix, file].join('/') } as #{ content_type }"
  bucket.objects[[prefix, file].join('/')].write file: file, acl: :public_read, content_type: content_type
end

puts "#{ '%2d' % (total + 1) } / #{ '%2d' % (total + 1) }: Uploading #{ [prefix, 'index.html'].join('/') } as text/html"
bucket.objects[[prefix, 'index.html'].join('/')].write file: 'index.html', acl: :public_read, content_type: 'text/html', cache_control: 'no-cache, must-revalidate'

Dir.chdir working_directory
`rm -rf build`
puts 'Done!'
