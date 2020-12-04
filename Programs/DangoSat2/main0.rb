#!mruby
#Ver.2.52
#Usb = Serial.new(0,115200)

# main.mrb を dango.mrbファイルとしてSDカードにコピーします
if(!System.use?('SD'))then
  System.exit("SD can't use.") 
end

puts "main.mrb copy to SD"
mname = "main.mrb"
sname = "dango.mrb"
fs = 0
fd = 1
fs = MemFile.open(fs, mname, 0) #mode=0 read
if(fs == -1)then
  System.exit("main.mrb can't open") 
end

if(SD.exists(mname) == 1)then
  SD.remove(mname)
end
if(SD.exists(sname) == 1)then
  SD.remove(sname)
end

fd = SD.open(fd, sname, 2)  #mode = 2 create
#if(fs == -1)then
#  System.exit("dango.mrb can't open") 
#end

while(true)do
  c = MemFile.read(fs)
  if(c < 0)then
    break
  end
  SD.write(fd, c.chr, 1)
  led
end  
SD.close(fd)
MemFile.close(fs)
puts "copy finished"

Pan = "0001"
Bc = "ffff"
puts "Change to program reception mode"

LoRa = Serial.new(1,115200)
while(LoRa.available > 0)do  #LoRa側のシリアルバッファクリア
  LoRa.read
end

##########################################
# UARTから　n バイトデータを読み込みます
##########################################
def getUART(uart, n)
  ary=[]
  exitCnt = 0
  i = 0
  while(exitCnt < 250)do
    ary[i] = uart.readOne()
    if(ary[i] != 0)then
      i += 1
      if(i >= n)then
        break
      end
    end
    exitCnt += 1
  end
  return ary
end

fnum = 0
while(true)do
  if(LoRa.available > 0)then
    cnt = 0
    lines = ""
    ke = 0
    while(cnt < 45)do
      c = getUART(LoRa, 1)
      lines += c[0].chr
      if(c[0] == 0xd)then
        ke = 1
      elsif(ke == 1 && c[0] == 0xa)then
        #改行 0D 0Aが来たのでブレイクします
        break
      else
        ke = 0
      end

      cnt += 1
      delay 1
    end
    puts lines.length  

    str = "0000000" + fnum.to_s
    fname = str[str.length-7..str.length] + ".pre"
    boo = SD.exists(fname)
    if(boo == true)then
      SD.remove fname
    end    

    puts fname
    fn = SD.open(0, fname, 2)
    SD.write(fn, lines, lines.length - 2)
    SD.close(fn)

    fnum += 1
    led
    if(lines.length < 34)then
      break
    end
  end
  delay 10
end

#デコードします
#mrb.preという1つのファイルを作ります
boo = SD.exists("mrb.pre")
if(boo == true)then
  SD.remove "mrb.pre"
end

fd = SD.open(0, "mrb.pre", 2)
fnum = 0
while(true)do
  str = "0000000" + fnum.to_s
  fname = str[str.length-7..str.length] + ".pre"

  fs = SD.open(1, fname, 0)
  lines = ""
  while(true)do
    c = SD.read(fs)
    if(c < 0)then
      break
    end
    lines += c.chr
  end
  SD.close(fs)

  SD.write(fd, lines, lines.length)
  fnum += 1
  led
  if(lines.length < 32)then
    break
  end
end
SD.close(fd)

#デコードします
boo = SD.exists("main.mrb")
if(boo == true)then
  SD.remove "main.mrb"
end
fd = SD.open(0, "main.mrb", 2)
fs = SD.open(1, "mrb.pre", 0)
kawari = []
kawari[0] = SD.read(fs)
kawari[1] = SD.read(fs)
kawari[2] = SD.read(fs)

len = SD.size(fs)
i = 3
d = 0
while(true)do
  if(d == 0)then
    c = SD.read(fs)
    i += 1
  else
    c = d
  end
  
  if(i == len)then
    SD.write(fd, c.chr, 1)
    break
  end

  if(c == kawari[0])then
    SD.write(fd, 0.chr, 1)
  elsif (c == kawari[1])then
    d = SD.read(fs)
    i += 1
    if(d == kawari[1])then
      SD.write(fd, kawari[0].chr, 1)
      d = 0
    end
  elsif (c == kawari[2])then
    d = SD.read(fs)
    i += 1
    if(d == kawari[2])then
      SD.write(fd, "\r\n", 2)
      d = 0
    end
  else
    SD.write(fd, c.chr, 1)
  end
  delay 1
  led
end
SD.close(fs)
SD.close(fd)

#main.mrbを実行します
MemFile.rm("main.mrb")
puts "main.mrb removed"
System.reset

