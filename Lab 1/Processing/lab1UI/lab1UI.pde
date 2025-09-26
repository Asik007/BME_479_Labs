//main file for the UI

//graph positioning on screen//
float graphX=180, graphY=-60, graphW, graphH;

//left panel positioning on screen
float lpX = 10, lpY = 10, lpW = 260, lpH;

interface ClickAction { void run(); }
boolean mouseLatch=false;

void drawButton(float x,float y,float w,float h,String label, ClickAction onClick){
  boolean over = mouseX>=x && mouseX<=x+w && mouseY>=y && mouseY<=y+h;
  fill(over?70:55); 
  stroke(90); 
  rect(x,y,w,h,8);
  fill(240); 
  textAlign(CENTER, CENTER); 
  text(label, x+w/2, y+h/2);
  if (over && mousePressed && !mouseLatch) { onClick.run(); mouseLatch=true; }
}
void mouseReleased(){ mouseLatch=false; }


// CALM MODE 
boolean calmActive = false; 
long calmStartMs = 0; 


//functions for calm mode
void startCalm() {
  if (calmActive) return;
  playMP3("piano.mp3");
  calmStartMs = millis();
  calmActive = true;
}

void stopCalm() {
  calmActive = false;
  stopMP3();
}

void setup() {
  size(1000, 640);
  lpH = height - 20; 
  graphW = width - graphX - 10;
  graphH = height - graphY - 20;

  graphSetup();
}

void draw() {
  background(18);

  //left panel
  pushStyle();
  noStroke(); 
  fill(28); 
  rect(lpX, lpY, lpW, lpH, 12);

  float cx = lpX + lpW/2.0, cy = lpY + lpH/2.0;
  int hr = graphGetHR();
  int conf = graphGetConf();


  // Big HR
  fill(240); textAlign(CENTER, CENTER); textSize(42); text(hr, cx, cy - 10);
  textSize(16); fill(180); text("bpm", cx, cy + 22);
  // Confidence
  textSize(14); fill(conf >= 80 ? 0xFFB4FFB4 : 0xFFE0C080);
  text("confidence: " + conf + "%", cx, cy + 44);


  float bx = 24, by = 60, bw = 220, bh = 28, gap = 10;
  drawButton(bx, by, bw, bh, "Calm",           () -> startCalm());     by+=bh+gap;
  drawButton(bx, by, bw, bh, "Stop Calm",      () -> stopCalm());      by+=bh+gap;
  popStyle();

// ==== RIGHT PANEL (centered + bigger graph) ====
noFill();
stroke(90);


// Original chart box inside graphDraw():
int srcX = 50, srcY = 100;   // where it starts inside graphDraw()
int srcW = 300, srcH = 200;  // chart size inside graphDraw()

// Pick your new (bigger) chart size:
int targetW = 520;           // <- make bigger here
int targetH = 320;           // <- and here (keep 300:200 ratio if you want)

// Scale factors to enlarge the chart
float sx = targetW / (float)srcW;
float sy = targetH / (float)srcH;

// The drawn content's full bounding box (includes the internal offset)
float bboxW = srcX * sx + targetW;
float bboxH = srcY * sy + targetH;

// Center that bounding box inside the right panel
pushMatrix();
translate(graphX, graphY);
float offX = (graphW - bboxW) * 0.5f;
float offY = (graphH - bboxH) * 0.5f;
translate(offX, offY);

// Scale only the graph; overlays you draw after this will be normal size
scale(sx, sy);
graphDraw();
popMatrix();

pushMatrix(); 
translate(graphX, graphY);

popMatrix();
}
