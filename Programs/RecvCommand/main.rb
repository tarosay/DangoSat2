#!mruby
#V2.53
Usb = Serial.new(0)

puts '"Waiting "#RECVPROG;"'

def CommandRead()
  readbuff = ""
  command_get = 0
  cnt = 0
  loop do
    while(Usb.available() > 0) do #何か受信があったらreadbuffに蓄える
      a = Usb.read()
      readbuff += a
      Usb.print a
      if a.to_s == ";" then
        command_get = 1
        break
      end
      delay 20
      cnt = 0
    end #while

    if readbuff.length > 0 then
      cnt += 1
      if cnt > 500 then
        command_get = 1
        break
      end      
      delay 20
    end    

    if command_get==1 || readbuff=="" then
      break
    end
  end #loop

  if command_get==1 then
    command_get = 0
    if(readbuff=="#RECVPROG;")then
      #ここで、mrbデータ取得プログラムを呼び出します
      
      puts ""
      puts "Command:" + readbuff
    else
      puts ""
      puts "Illegal command:" + readbuff
      readbuff = ""
    end #if
  end
end

loop do
  CommandRead()
  delay 10
end

