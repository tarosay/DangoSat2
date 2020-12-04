#!mruby
#Ver.2.53
#
# main.mrbをSDカードにコピーして、フラッシュメモリにあるmain.mrbを削除します
# フラッシュメモリ内にmain.mrbが無い場合は、SDカード内のmain.mrbを実行します。また、main.mrbはフラッシュメモリにコピーされます。

if(!System.use?('SD'))then
  System.exit("SD can't use.") 
end

puts "main.mrb copy to SD"
mname = "main.mrb"
sname = "main.mrb"
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
if(fs == -1)then
  System.exit("main.mrb can't open") 
end

while(true)do
  c = MemFile.read(fs)
  if(c < 0)then
    break
  end
  SD.write(fd, c.chr, 1)
end  
SD.close(fd)
MemFile.close(fs)

puts "main.mrb copy finished"

MemFile.rm(mname)
puts "main.mrb removed"
