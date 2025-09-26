import processing.sound.*;

SoundFile file;

void playMP3(String filename) {
  try {
    if (file != null) file.stop();
    file = new SoundFile(this, filename);
    file.play();
  } catch (Exception e) {
    println("playMP3 error: " + e.getMessage());
  }
}

void stopMP3() {
  try { if (file != null) file.stop(); } catch (Exception e) {}
}
