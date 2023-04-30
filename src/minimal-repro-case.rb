require 'shell'

# Run some commands using backticks, leaves dangling IO objects
`echo`

# GC after backticks execution cleans those dangling IO objects!
GC.start if ARGV.first == 'gc'

# Run some commands using Shell, fails on ruby > 3.1.0
sh = Shell.new
sh.transact do
  system("echo")
end

# Code from process-controller.rb:259 with added rescue to highlight problem
ObjectSpace.each_object(IO) do |io|
  if ![STDIN, STDOUT, STDERR].include?(io)
    begin
      io.close
    rescue IOError => e
      puts "#{io.inspect}, #{e}"
    end
  end
end
