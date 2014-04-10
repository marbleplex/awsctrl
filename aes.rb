#!/usr/bin/env ruby

class AES
  require "openssl"

  def initialize(data, password, base64)
    @data = data
    @password = password
    @base64 = base64
  end

  def encrypt_data
    salt = OpenSSL::Random.random_bytes(8)
    cipher = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    cipher.encrypt
    cipher.pkcs5_keyivgen(@password, salt)
    out = cipher.update(@data) + cipher.final
    out = "Salted__" + salt + out
    @base64 ? [out].pack("m") : out
  end

  def decrypt_data
    @data = @data.unpack("m")[0] if @base64
    salt = @data[8, 8]
    cipher = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    cipher.decrypt
    cipher.pkcs5_keyivgen(@password, salt)
    out = cipher.update(@data[16, @data.size]) + cipher.final
    out
  end
  
  def usage
    STDERR.puts "aes = AES.new(command, data, password, [base64])"
    STDERR.puts "aes.encrypt_data  or  aes.decrypt_data"
  end
end

def usage
  STDERR.puts "#{File::basename((__FILE__).sub(/\.\//,''))} command(-e,-d) [base64(-b)] file"
  STDERR.puts "    command : '-e' -> encrypt, '-d' -> decrypt"
  STDERR.puts "    base64  : '-b' -> base64"
  STDERR.puts "    outfile : '-o outfile'  # for bigdata"
  exit
end

if $0 == __FILE__
  require "fileutils"
  require "optparse"
  require "rubygems"
  require "highline/import"

  options = Hash.new
  OptionParser.new do |opts|
    opts.on("-e", "--encrypt") do |v|
      options[:encrypt] = v
    end
    opts.on("-d", "--decrypt") do |v|
      options[:decrypt] = v
    end
    opts.on("-b", "--base64")  do |v|
      options[:base64]  = v
    end
    opts.on("-o", "--outfile=VAL")  do |f|
      options[:outfile]  = f
    end
  end.parse!

  command = "e" if options[:encrypt]
  command = "d" if options[:decrypt]
  base64  = options[:base64]
  data    = File.exists?(ARGV[0]) && File.open(ARGV[0], "rb").read
  usage if (command.nil? or data.nil?) 
  password = ask("password: "){|q| q.echo = '*'}
  aes = AES.new(data, password, base64)
  options[:outfile] ? fh = File.open(options[:outfile], "wb") : fh = STDOUT
  if command == "e"
    fh.print aes.encrypt_data
  elsif command == "d"
    fh.print aes.decrypt_data
  end
  fh.close if fh
end

### how to use openssl encrypt
#http://webos-goodies.jp/archives/encryption_in_ruby.html
#http://webos-goodies.googlecode.com/svn/trunk/blog/articles/encryptin_in_ruby/encrypt.rb
#http://alpha.mixi.co.jp/blog/?p=91
#https://nona.to/fswiki/wiki.cgi?page=OpenSSL+Command-Line+HOWTO
