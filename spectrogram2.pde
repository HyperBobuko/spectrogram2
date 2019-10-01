import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;
AudioInput in;
AudioPlayer player;
FFT fft;
int fftsize;

int bufferSize = 2048;

int gain = 1000;

int magnify = 1;

int color_selection = 5;

boolean musicMode = false;

int height_spectrogram;

boolean fft_null_sts = true;

void setup()
{
  //size(1200, 800);
  fullScreen();
  height_spectrogram = (int)(height *0.75);
  stroke(0);
  frameRate(20);
  background(0);
  fill(0);
  rect(0, 0, width, height);

  minim = new Minim(this);
}

void draw()
{
  drawWave();

  stroke(0);
  if (fft != null) {
    try {
      if (musicMode && player != null) {
        fft.forward(player.mix);
        //println(1);
      } else {
        fft.forward(in.mix);
        //println(fft.getBand(0));
      }
    }

    catch(Exception e) {
      println(e);
      System.exit(0);
    }
  }
  loadPixels();
  int update_x = (frameCount < width)? frameCount : width-1;
  for (int i = 0; i < width*height_spectrogram; i++) {
    int fftIndex = i / width;
    int idx = i+ width*(height - height_spectrogram);
    float val = 
      (fftIndex!=0)? 
      ( (fft != null)?
      ( (fftIndex!=2)?
      ( (fftsize < height_spectrogram)?
      ( (fftIndex < (height_spectrogram - fftsize))?
      0
      : fft.getBand((height_spectrogram-fftIndex)/magnify)*gain )
      : fft.getBand((height_spectrogram-fftIndex)/magnify)*gain )
      : 255 )
      : 0 )
      : 255;

    if (idx%width == update_x) {
      pixels[idx] = strokeColor(color_selection, val);
    } else {
      if (frameCount != update_x) {
        pixels[idx] = pixels[idx+1];
      }
    }
  }
  updatePixels();

  stroke(strokeColor(color_selection, 255));
  if (fft_null_sts && fft!=null) {
    line(update_x-5, height - height_spectrogram +6, update_x-1, height - height_spectrogram+6);
    line(update_x-3, height - height_spectrogram +4, update_x-3, height - height_spectrogram+8);
    fft_null_sts = false;
  } else if (!fft_null_sts && fft==null) {
    line(update_x-5, height - height_spectrogram +6, update_x-1, height - height_spectrogram+6);
    fft_null_sts = true;
  }
}

void listen() {
  if (fft == null && !musicMode) {
    surface.setTitle("spectrogram : Listen mode");
    in = minim.getLineIn(Minim.STEREO, bufferSize);
    
    fft = new FFT(bufferSize, in.sampleRate());
    fftsize = fft.specSize();
    println("[Listen]");
    println("buffer size : " +bufferSize);
    println("sampling rate : " +in.sampleRate());
    println("fft spec size : " +fft.specSize());
    println("fft bandwidth : " +fft.getBandWidth());
    gain = 1000;
  }
}

void stopListen() {
  if (in != null) {
    in.close();
  }
  if (fft != null) {
    fft=null;
  }
}

void openFile() {
  selectInput("Select a file to process:", "fileSelected");
}

void fileSelected(File selection) {
  if (selection != null) {
    surface.setTitle(("spectrogram : ♪ Playing "+selection.getName()).replace(".mp3", ""));

    musicMode = true;
    player = minim.loadFile(selection.getAbsolutePath(), bufferSize);
    player.loop();
    
    fft = new FFT(bufferSize, player.sampleRate());
    fftsize = fft.specSize();
    println("[Play music]");
    println("buffer size : " +bufferSize);
    println("sampling rate : " +player.sampleRate());
    println("fft spec size : " +fft.specSize());
    println("fft bandwidth : " +fft.getBandWidth());
    gain = 10;
  } else {
    closeFile();
  }
}

void closeFile() {
  if (player != null) {
    player.close();
    fft = null;
  }
  if (musicMode) {
    musicMode = false;
  }
}

void stop()
{
  in.close();
  player.close();
  minim.stop();
  super.stop();
}

void keyPressed() {
  if (key == 'l') {
    listen();
  } else if (key == 's') {
    surface.setTitle("spectrogram");
    stopListen();
    closeFile();
  } else if (key == 'o') {
    //surface.setTitle("spectrogram");
    stopListen();
    closeFile();
    openFile();
  } else if (key == 'c') {
    color_selection = (color_selection ==13)? 1: color_selection+1;
  } else if (key == 'r') {
    frameCount = 0;
  } else if (key == ' ') {    
    loadPixels();
    for (int i = 0; i < width*height; i++) {
      pixels[i]= color(0, 0, 0);
    }
    updatePixels();
  } else if (keyCode == RIGHT) {
    int move = 100;
    if (move < frameCount) {
      loadPixels();
      for (int i = 0; i < width*height_spectrogram; i++) {
        int idx = i+ width*(height - height_spectrogram);
        pixels[idx]= (idx % width + move > width-1)? color(0, 0, 0): pixels[idx + move];
      }
      updatePixels();
      if (frameCount>width-1) frameCount=width-1;
      frameCount -= move;
    }
  } else if (keyCode == LEFT) {
    int move = 100;
    if (frameCount+move < width) {
      loadPixels();
      for (int i = width*height_spectrogram-1; i > -1; i--) {     
        int idx = i+ width*(height - height_spectrogram);
        pixels[idx]= (idx % width - move < 0)? color(0, 0, 0): pixels[idx - move];
      }
      updatePixels();
      frameCount += move;
    }
  } else if (keyCode == UP) {
    if (magnify < 8) {  
      magnify*=2;
    }
  } else if (keyCode == DOWN) {
    if (magnify > 1) {  
      magnify/=2;
    }
  }
}

color strokeColor(int state, float val) {
  color col;
  if (state>13) {
    state -=13;
  }
  switch(state) {
  case 1:
    col = color(val, val/2.5, 0);
    break;
  case 2:
    col = color(0, val, val/2.5);
    break;
  case 3:
    col = color(val/2.5, 0, val);
    break;
  case 4:
    col = color(val, 0, val/2.5);
    break;
  case 5:
    col = color(val/2.5, val, 0);
    break;
  case 6:
    col = color(0, val/2.5, val);
    break;
  case 7:
    col = color(val, val/2.5, val/2.5);
    break;
  case 8:
    col = color(val/2.5, val, val/2.5);
    break;
  case 9:
    col = color(val/2.5, val/2.5, val);
    break;
  case 10:
    col = color(val, val, val/2.5);
    break;
  case 11:
    col = color(val/2.5, val, val);
    break;
  case 12:
    col = color(val, val/2.5, val);
    break;
  case 13:
    col = color(val, val, val);
    break;
  default:
    col = color(val, val/2.5, 0);
  }
  return col;
}

void drawWave() {
  noStroke();
  fill(0, 64);
  rect(0, 0, width, height - height_spectrogram);

  stroke(strokeColor(color_selection, 255));
  int waveH = (height - height_spectrogram )/2;
  int waveW = 0;
  int x_comp = 1;
  if (musicMode && player != null) {
    waveW = (player.bufferSize()-1 < width*x_comp)? player.bufferSize()-1:width*x_comp;
    for (int i = 0; i < waveW; i++)
    {
      float x = i/x_comp + (waveW/x_comp<width? (width-waveW/x_comp)/2:0);
      float y = abs(player.mix.get(i)*waveH);
      y = y>waveH-1? waveH-1:y;
      line(x, waveH - y, x, waveH + y);  //音声の波形を画面上に描く
    }
  } else if (in != null) {
    waveW = (in.bufferSize()-1 < width*x_comp)? in.bufferSize()-1:width*x_comp;
    for (int i = 0; i < waveW; i++)
    {
      float x = i/x_comp + (waveW/x_comp<width? (width-waveW/x_comp)/2:0);
      float y = abs(in.mix.get(i)*waveH*20);
      y = y>waveH-1? waveH-1:y;
      line(x, waveH - y, x, waveH + y);  //音声の波形を画面上に描く
    }
  }
}