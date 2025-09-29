// ===== Lab1UI.pde =====
// Modes only control music/overlays. Classifier (Calm/Stressed/Resting) runs continuously once baseline exists.

import controlP5.*;

// layout
float graphX = 10, graphY = -5, graphW, graphH;
float lpX = 10, lpY = 10, lpW = 260, lpH;

// baseline
boolean baselineActive = false;
long    baselineStartMs = 0;
int     baselineDurationMs = 30000;
IntList baselineSamples = new IntList();
int     baselineHR = 0;

// calm mode
boolean calmActive = false;
long    calmStartMs = 0;

int     calmDeltaBpm = 3;  // <= baseline-3 for calm
int     calmMinConf  = 40;
int     calmDwellMs  = 3000;

boolean userIsCalm = false;     // classifier output
long    calmCandidateStart = 0; // dwell timers
long    restCandidateStart = 0;

// stressed mode
boolean stressedActive = false;
long    stressedStartMs = 0;
int     stressedDurationMs = 60000;

int     stressedDeltaBpm = 5;        // >= baseline+5 for stressed
int     stressedDwellMs  = 3000;

boolean userIsStressed   = false;    // classifier output
long    stressedCandStart = 0;
long    deStressCandStart = 0;

//might not even need this but just keep it there idk
boolean prevUserIsStressed = false;

//helpers
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

void startStressed() {
  if (stressedActive) return;
  stressedActive   = true;
  stressedStartMs  = millis();
  stressedCandStart = 0;
  deStressCandStart = 0;
}

void stopStressed() {
  stressedActive = false;
  stressedCandStart = 0;
  deStressCandStart = 0;
  //stop the fucking beeping bro hoky fuck
  try { myPort.write("stop please"); } catch (Exception ex) { println("Serial write failed: " + ex); }

}

void startBaseline(){
  baselineActive = true;
  baselineStartMs = millis();
  baselineSamples.clear();
  baselineHR = 0;
  println("Baseline started…");
}

//get average
void stopBaseline(){
  baselineActive = false;
  if (baselineSamples.size() > 0) {
    float sum = 0;
    for (int i = 0; i < baselineSamples.size(); i++) sum += baselineSamples.get(i);
    baselineHR = round(sum / baselineSamples.size());
    println("Baseline set to " + baselineHR + " bpm from " + baselineSamples.size() + " samples.");
  } else {
    println("Baseline cancelled / no samples.");
  }
}

// setup
void setup() {
  size(1000, 640);
  lpH = height - 20;
  graphW = width - graphX - 10;
  graphH = height - graphY - 20;

  graphSetup();  // from graph.pde

  // Buttons (ControlP5)
  cp5.addButton("calmButton").setLabel("Calm Mode").setPosition(int(lpX+14), int(lpY+60)).setSize(220, 28);
  cp5.addButton("stopCalmButton").setLabel("Stop Calm Mode").setPosition(int(lpX+14), int(lpY+98)).setSize(220, 28);
  cp5.addButton("startStressedButton").setLabel("Stressed (60s)").setPosition(int(lpX+14), int(lpY+140)).setSize(220, 34);
  cp5.addButton("stopStressedButton").setLabel("Stop Stressed").setPosition(int(lpX+14), int(lpY+182)).setSize(220, 34);
  cp5.addButton("startBaselineButton").setLabel("Start 30s Baseline").setPosition(int(lpX+14), int(lpY+224)).setSize(220, 28);
  cp5.addButton("stopBaselineButton").setLabel("Stop Baseline (Compute)").setPosition(int(lpX+14), int(lpY+262)).setSize(220, 28);

  PFont btnFont = createFont("Arial", 8);
  cp5.getController("calmButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
  cp5.getController("stopCalmButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
  cp5.getController("startStressedButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
  cp5.getController("stopStressedButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
  cp5.getController("startBaselineButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
  cp5.getController("stopBaselineButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
}

// Button callbacks
void calmButton()            { startCalm(); }
void stopCalmButton()        { stopCalm();  }
void startStressedButton()   { startStressed(); }
void stopStressedButton()    { stopStressed();  }
void startBaselineButton()   { startBaseline(); }
void stopBaselineButton()    { stopBaseline();  }

//draw
void draw() {
  background(18);

  // Left panel
  pushStyle();
  noStroke();
  fill(28);
  rect(lpX, lpY, lpW, lpH, 12);

  float cx = lpX + lpW/2.0, cy = lpY + lpH/2.0;
  int hr = graphGetHR();
  int conf = graphGetConf();

  // Vitals
  fill(240); textAlign(CENTER, CENTER); textSize(42); text(hr, cx, cy);
  textSize(16); fill(180); text("Current bpm", cx, cy + 32);
  textSize(14); fill(conf >= 80 ? 0xFFB4FFB4 : 0xFFE0C080); text("confidence: " + conf + "%", cx, cy + 64);
  
  //the time between beats
  int ibi = graphGetIBI();
  textSize(14); fill(180);
  text("~ " + ibi + " ms between beats", cx, cy + 86);
  
  // SpO2 line
  String spo2Text = (graphGetSpO2() > 0) ? (graphGetSpO2() + "% SpO₂") : "SpO₂ —";
  text(spo2Text, cx, cy + 104);

  // Baseline progress
  if (baselineActive) {
    if (conf >= calmMinConf && hr > 0) baselineSamples.append(hr);
    int remain = max(0, baselineDurationMs - int(millis() - baselineStartMs));
    if (remain <= 0) stopBaseline();

    fill(180); textAlign(CENTER, TOP); textSize(12);
    text("Baseline recording… " + nf(remain/1000, 2) + "s left (" + baselineSamples.size() + " samples)",
         lpX + lpW/2, cy + 80);
  }
  if (baselineHR > 0) {
    fill(180); textAlign(CENTER, TOP); textSize(12);
    text("Baseline: " + baselineHR + " bpm", lpX + lpW/2, cy + 80);
  }
  popStyle();

  // Right panel: scale/center graph
  noFill(); stroke(90);
  int srcX = 50, srcY = 100, srcW = 300, srcH = 200;
  int targetW = 400, targetH = 300;
  float sx = targetW / (float)srcW, sy = targetH / (float)srcH;
  float bboxW = srcX * sx + targetW, bboxH = srcY * sy + targetH;
  pushMatrix();
  translate(graphX, graphY);
  float offX = (graphW - bboxW) * 0.5f, offY = (graphH - bboxH) * 0.5f;
  translate(offX, offY);
  scale(sx, sy);
  graphDraw();
  popMatrix();

  // calm detection
  if (baselineHR > 0 && conf >= calmMinConf) {
    long now = millis();
    if (!userIsCalm) {
      // become Calm
      if (hr <= baselineHR - calmDeltaBpm) {
        if (calmCandidateStart == 0) calmCandidateStart = now;
        if (now - calmCandidateStart >= calmDwellMs) {
          userIsCalm = true;
          restCandidateStart = 0;
        }
      } else {
        calmCandidateStart = 0;
      }
    } else {
      // leave Calm
      if (hr >= baselineHR) {
        if (restCandidateStart == 0) restCandidateStart = now;
        if (now - restCandidateStart >= calmDwellMs) {
          userIsCalm = false;
          calmCandidateStart = 0;
        }
      } else {
        restCandidateStart = 0;
      }
    }
  } else {
    // no good signal/baseline -> reset dwell timers
    calmCandidateStart = 0;
    restCandidateStart = 0;
  }

  //stressed detection
  if (baselineHR > 0 && conf >= calmMinConf) {
    long now = millis();
    if (!userIsStressed) {
      // become Stressed
      if (hr >= baselineHR + stressedDeltaBpm) {
        if (stressedCandStart == 0) stressedCandStart = now;
        if (now - stressedCandStart >= stressedDwellMs) {
          userIsStressed = true;
          deStressCandStart = 0;
        }
      } else {
        stressedCandStart = 0;
      }
    } else {
      // leave Stressed
      if (hr <= baselineHR + 1) {
        if (deStressCandStart == 0) deStressCandStart = now;
        if (now - deStressCandStart >= stressedDwellMs) {
          userIsStressed = false;
          stressedCandStart = 0;
        }
      } else {
        deStressCandStart = 0;
      }
    }
  }

  // buzzer logic
  if (baselineHR > 0 && userIsStressed) {
    println("BEEP edge: hr=" + hr + " baseline=" + baselineHR + " conf=" + conf);
    try { myPort.write('b'); } catch (Exception ex) { println("Serial write failed: " + ex); }
  }
  prevUserIsStressed = userIsStressed;

  // auto stop stress mode after 60 sec
  if (stressedActive && (millis() - stressedStartMs >= stressedDurationMs)) stopStressed();

  // stress mode overlay
  if (stressedActive) {
    int remain = max(0, stressedDurationMs - int(millis() - stressedStartMs));
    float pad = 12, w = 220, h = 72;
    float x = graphX + pad, y = graphY + pad;
    pushStyle();
    noStroke(); fill(30, 200); rect(x, y, w, h, 10);
    fill(230); textAlign(CENTER, TOP); textSize(14);
    text("Stressed Mode", x + 700, y + 8);
    text("Time left: " + nf(remain/1000, 2) + "s", x + 700, y + 28);
    popStyle();
  }

  //user state badge 
  String label;
  color labelColor;
  if (userIsStressed) {
    label = "Stressed"; labelColor = color(255,120,120);
  } else if (userIsCalm) {
    label = "Calm";     labelColor = color(140,220,170);
  } else {
    label = "Resting";  labelColor = color(210);
  }

  float pad = 12, bw = 190, bh = 54;
  float bx = graphX + graphW - bw - pad;
  float by = graphY + pad;
  pushStyle();
  noStroke(); fill(30, 200); rect(bx, by, bw, bh, 10);
  fill(200); textAlign(CENTER, TOP); textSize(14); text("User is:", bx + bw/2, by + 6);
  fill(labelColor); textAlign(CENTER, CENTER); textSize(20); text(label, bx + bw/2, by + bh/2 + 6);
  popStyle();
}
