#!mruby
#Ver.2.53
Usb = Serial.new(0,115200)
LoRa = Serial.new(1,115200)
Pan = "0001"
Bc = "ffff"
BinFile = "main1.mrb"

#LoRa.println Pan + Bc + "#RECVPROG;"
delay 1000

#LoRaに送信します
MemFile.open(0, BinFile, 0)
  c = 0
  while(c >= 0)do
    #32バイト読み込む
    c32 = ""
    i = 0
    while(i < 32)do
      c = MemFile.read(0)
      if(c < 0)then
        break
      end
      c32 += c.chr
      i += 1
    end

    LoRa.println Pan + Bc + c32
    #Usb.write(c32, c32.length)
    puts c32
    puts c32.length
    delay 1000
    led
  end  
MemFile.close(0)

 
#for i in 1..15
#  a = ""
#  for j in 0..15
#    a = a + (i * 16 + j).chr
#  end
#  LoRa.println Pan + Bc + a
#  delay 2000
#end
