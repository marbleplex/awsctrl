#!/usr/bin/env ruby
# coding: utf-8

require "right_aws"
require "highline/import"
require "date"
require_relative "./aes.rb"

c_data = File.open("#{File.dirname(__FILE__)}/c_data").read

password = ask("password: "){|q| q.echo = '*'}
aes = AES.new(c_data, password, true) # base64mode
aws_key, aws_secret = aes.decrypt_data.split(',')

ec2 = RightAws::Ec2.new(aws_key, aws_secret, :endpoint_url => 'https://ec2.ap-southeast-1.amazonaws.com')

def get_status(ec2)
  instances = []
  ec2.describe_instances.each do |i|
    instances << [ i[:aws_instance_id], i[:aws_state], i[:ip_address] ]
  end
  instances
end

loop do
  ### status:stopped->pending(15sec)->runnning->stopping(15sec)->stopped
  state = get_status(ec2)
  puts "[#{Time.now.strftime("%Y/%m/%d %H:%M:%S")}] #{state.join(' : ')}"
  STDERR.puts "## s[C]can | [S]top | sta[R]t | [Q]uit ##"
  #if %w(stopped running).include?(state[1])
  case STDIN.gets.rstrip.downcase
  when "s"
    puts "#{state[0][0]} is stopping"
    ec2.stop_instances(state[0][0])
  when "r"
    puts "#{state[0][0]} is starting"
    ec2.start_instances(state[0][0])
  when "q"
    exit
  else
    #redo
  end
  sleep 2
end

