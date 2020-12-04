#!mruby
#Ver.2.52
Usb = Serial.new(0,115200)
LoRa = Serial.new(1,115200)
Gps = Serial.new(2,9600)
Pan = "0001"
Bc = "ffff"
RtcFlg = 0
Ido1 = 0
Kei1 =0
Kyo1 = 10000
Log = "0000000.csv"
Ster = 0
pinMode(8, OUTPUT)
Servo.attach(Ster, 8)
Oido = 33.43727
Okei = 135.76276
Odir = 0  #方向
puts "DangoSat2 System Start"

while(Usb.available > 0)do	#USBのシリアルバッファクリア
  Usb.read
end
while(LoRa.available > 0)do  #LoRa側のシリアルバッファクリア
  LoRa.read
end
while(Gps.available > 0)do  #Gps側のシリアルバッファクリア
  Gps.read
end
if(!System.use?('SD'))then
  System.exit("SD can't use.") 
end

####################################
# デリミタ 0Aで #RECVPROG を受信します
###################################
def CommandRead()
  dev = LoRa
  readbuff = ""
  command_get = 0
  cnt = 0
  loop do
    while(dev.available() > 0) do #何か受信があったらreadbuffに蓄える
      a = dev.read()
      readbuff += a
      #Usb.print readbuff

      if readbuff[readbuff.length - 3] == ";" then
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

      if(readbuff[0] != "#")then
        return
      end
      #puts command_get.to_s + ">>" + readbuff
      #puts readbuff[readbuff.length - 3] 

      delay 20
    end    

    if(command_get == 1 || readbuff == "")then
      break
    end
  end #loop

  if command_get==1 then
    command_get = 0
    if(readbuff[0..9]=="#RECVPROG;")then
      # 0001ffff#RECVPROG;
      #ここで、mrbデータ取得プログラムを呼び出します
      puts ""
      puts "Command:" + readbuff
      System.setrun("main0.mrb")
      System.exit
    else
      puts ""
      puts "Illegal command:" + readbuff
      readbuff = ""
    end #if
  end
end

def steer(p)
  cen = 82
  s0 = 64
  s1 = 100
  if(p == 0)then
    Servo.write(Ster, cen)
    return  
  elsif(p < -10 || p > 10)then
    return
  end
  k = cen + 1.8 * p
  Servo.write(Ster, k)
end
###################################
# SDメモリとLoRaにデータを出力
###################################
def writeData(dat)
  fn = SD.open(0, Log, 1)
  if(fn < 0)then
    fn = SD.open(0, Log, 2)
    if(fn < 0)then
      #LoRaに送信します
      LoRa.println Pan + Bc + "SD Open Error"
      return
    end
  end
  tm = Rtc.getTime
  dd = zeroAdd(tm[0]) + "/" + zeroAdd(tm[1]) + "/" +zeroAdd(tm[2]) + ","
  dh =  zeroAdd(tm[3]) + ":" + zeroAdd(tm[4]) + ":" +zeroAdd(tm[5]) + ","
  doc = dd + dh + dat + "\r\n"
  SD.write(fn, doc, doc.length)
  SD.close(fn)

  #LoRaに送信します
  LoRa.println Pan + Bc + dh + dat
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

##########################################
# RTCのチェック
##########################################
def rtc_check(dy,dm,dd,th,tm,ts)
  tm1 = Rtc.getTime
  delay 1100
  tm2 = Rtc.getTime
  #puts tm1[0].to_s 
  if(tm1[5] == tm2[5] || tm1[0] < 2019)then
      puts 'RTC Initialized'
      Rtc.init
      Rtc.setTime([dy,dm,dd,th,tm,ts])
  end
end
def zeroAdd(num)
  str = "00" + num.to_s
  str[str.length-2..str.length]
end

##########################################
# GPSの処理をおこないます
##########################################
def gpsRead()
  if(Gps.available <= 0)then
    return
  end
  exitCnt = 0
  cnt = 0
  kei = 0
  ido = 0
  kyo = 0
  while(exitCnt < 500)do
    c = getUART(Gps,1)
    if(c[0] == 0x24)then  # $の検出　
      # 5バイト読み込む
      h = getUART(Gps,5)
      lines = "$" + h[0].chr + h[1].chr + h[2].chr + h[3].chr + h[4].chr
      #puts lines

      if(lines == "$GPRMC")then  # $GPRMC の検出
      #if(lines == "$GPGGA")then  # $GPGGA の検出
        #改行まですべて取り込む
        while true do
          c = getUART(Gps,1)
          lines = lines + c[0].chr
          if(c[0] == 0x0A)then
            break
          elsif(lines.length > 80)then  #80バイト取り込んでも0x0Aが来ないときは取り込みをやめる
            break
          end
          delay 0
        end
        #puts lines
        cPos0 = 0
        cPos1 = 0
        cCnt = 0
        for i in 0..lines.length - 1
          if(lines[i] == ",")then
            cPos0 = cPos1
            cPos1 = i
            cCnt += 1
            #puts "cPos0 = " + cPos0.to_s
            #puts "cPos1 = " + cPos1.to_s
          elsif(lines[i] == "C")then
            #HHMMSS.sss
            tims = lines[(cPos0+7)..(cPos1-1)]
            timH = tims[0..1]
            timM = tims[2..3]
            timSec = tims[4..5]
            #puts timH + ":" + timM + ":" + timSec
          elsif(lines[i] == "N")then
            idos = lines[(cPos0+1)..(cPos1-1)]
            idoFun = idos[idos.length-8+1..idos.length-1]
            idoI = idos[0..idos.length-8]
            ido = idoI.to_f + idoFun.to_f / 60
          elsif(lines[i] == "E")then
            keidos = lines[(cPos0+1)..(cPos1-1)]
            keidoFun = keidos[keidos.length-8+1..keidos.length-1]
            keidoI = keidos[0..keidos.length-8]
            kei = keidoI.to_f + keidoFun.to_f / 60
          end
          
          if(cCnt == 10)then
            dates = lines[(cPos0+1)..(cPos1-1)]
            #puts dates
            dateD = dates[0..1]
            dateM = dates[2..3]
            dateY = "20" + dates[4..5]
            #puts dateY + "/" + dateM + "/" + dateD

            if(RtcFlg == 0)then
              #RTCを合わします
              rtc_check(dateY.to_i, dateM.to_i, dateD.to_i, timH.to_i, timM.to_i, timSec.to_i)
              #Logファイル名を生成します
              boo = SD.exists(Log) 
              while(boo == 1)do
                n = Log[0..6].to_i
                n += 1
                str = "0000000" + n.to_s
                str = str[str.length-7..str.length]
              
                Log = str + ".csv"
                #puts Log
                boo = SD.exists(Log) 
                delay 0
              end
              puts Log
              RtcFlg = 1
            end

            break
          end
        end

        #現在緯度と経度から傾きと目標地点までの距離を求めます
        if(kei > 0 && ido > 0)then
          kyo = (ido - Oido) * (ido - Oido) + (kei - Okei) * (kei - Okei)
          saIdo = ido - Ido1
          saKei = kei - Kei1
          
          if((saIdo >= 0 && saKei >= 0) || (saIdo < 0 && saKei < 0))then
            if(Kyo1 > kyo)then
              Odir += 1
            else
              Odir = 0
            end
          else
            if(Kyo1 > kyo)then
              Odir -= 1
            else
              Odir = 0
            end
          end

          if(Odir > 10)then
            Odir = 10
          elsif(Odir<-10)then
            Odir = -10
          end
          #ステアリングを切ります
          steer Odir

          Ido1 = ido
          Kei1 = kei
          Kyo1 = kyo
        end
        dat = ido.to_s + "," + kei.to_s + "," + kyo.to_s + "," + Odir.to_s
        #puts dat

        #SDメモリとLoRaにデータを出力
        writeData(dat)

        cnt += 1
      end    
    end
    if(cnt == 1)then
      while(Gps.available > 0)do  #Gps側のシリアルバッファクリア
        Gps.read
      end      
      return
    end
    exitCnt += 1
  end
  #puts "A:" + exitCnt.to_s
end

#============================================================================
#ステアリングを初期化します
steer Odir
while true
  gpsRead
  led
  delay 0
  CommandRead()
  while(LoRa.available > 0)do  #LoRa側のシリアルバッファクリア
   LoRa.read
  end  
end
