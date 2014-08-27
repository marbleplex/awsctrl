#!/usr/bin/env ruby
# coding: utf-8

require "aws-sdk"
require "highline/import"
require "date"
require_relative "./aes.rb"

c_data = File.open("#{File.dirname(__FILE__)}/c_data").read

password = ask("password: "){|q| q.echo = '*'}
aes = AES.new(c_data, password, true) # base64mode
aws_key, aws_secret = aes.decrypt_data.split(',')

ec2 = AWS::EC2.new(
  :ec2_endpoint      => 'ec2.ap-southeast-1.amazonaws.com',
  :access_key_id     => aws_key,
  :secret_access_key => aws_secret
)

def get_status(ec2)
  ec2.instances.map do |i|
    [ i.id, i.status, i.ip_address ]
  end
end

loop do
  ### status:stopped->pending(15sec)->runnning->stopping(15sec)->stopped
  state = get_status(ec2)
  puts "[#{Time.now.strftime("%Y/%m/%d %H:%M:%S")}] #{state.join(' : ')}"
  STDERR.puts "## s[C]can | [S]top | sta[R]t | [Q]uit ##"
  id = state[0][0]
  ins = ec2.instances[id]
  case STDIN.gets.rstrip.downcase
  when "s"
    puts "#{id} is stopping"
    ins.stop
  when "r"
    puts "#{id} is starting"
    ins.start
  when "q"
    exit
  else
    #redo
  end
  sleep 2
end

