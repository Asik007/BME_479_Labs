import processing.sound.*;

SoundFile file;
long startTime;
boolean playing = false;


void playMP3(String filename, int duration) {
  file = new SoundFile(this, filename);
  file.play();
  startTime = millis();
  playing = true;

  while (playing) {
    long elapsedTime = millis() - startTime;
    if (elapsedTime >= duration) {
      file.pause();
      playing = false;
    }
    delay(10); 
  }
}

void setup() {
  size(640, 360);
  background(255);

  playMP3("breakstuff.mp3", 15000);
}

void draw() {
  // left empty since timing is handled in playMP3
}
