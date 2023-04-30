`echo`
ObjectSpace.each_object(IO) do |io|
  if ![STDIN, STDOUT, STDERR].include?(io)
    io.close
  end
end
