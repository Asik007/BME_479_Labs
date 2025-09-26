//main file for the UI

//THIS IS PART 2. WE WILL TREAT THE CURRENT BPM DISPLAY AS THE RESTING HEART RATE
//WHEN THE USER CLICKS THE START CALM BUTTON, WE WILL PLAY MUSIC AND SCAN IF THE USERS CURRENT BPM REDUCES BY 3
//FOR ATLEAST 3 SECONDS, IF THAT IS THE CASE, THE USER STATE BADGE TO THE RIGHT OF THE GRAPH WILL DENOTE THAT THE USER IS CALM, 
//OTHERWISE IT IS DENOTED AS RESTING

//FOR STRESSED MODE, THE CURRENT BPM WILL AGAIN BE USED AS THE RESTING HEART RATE. WHEN THE USER PRESSES THE STRESSED MODE BUTTON
// A TIMER FOR 60 SECONDS BEGINS, THIS IS THE TIME FOR OUR STRESSED MODE TRIAL RUN, IF CURRENT BPM GOES ABOVE BY 8 BPM FOR AT LEAST 
// 3 SECONDS, WE DENOTE THAT THE USER IS STRESSED. AFTER 60 SECONDS STRESSED MODE STOPS. WHEN USERS STATE IS DENOTED AS STRESSED
// THE BUZZER WILL SOUND 
//STRESS DETECTION IS ONLY ACTIVE WHEN STRESS MODE IS CLICKED BY THE USER. 

import controlP5.*; 

//graph positioning on screen
float graphX=10, graphY=-5, graphW, graphH;

//left panel positioning on screen
float lpX = 10, lpY = 10, lpW = 260, lpH;


// CALM MODE globals
boolean calmActive = false; 
long calmStartMs = 0; 

int     restingHR = 0;         // set at Calm start or the first good sample we get of the current bpm
int     calmDeltaBpm = 3;      // threshold to call it Calm
int     calmMinConf  = 40;     // ignore low-confidence
int     calmDwellMs  = 3000;   // hold 3 sec to switch

boolean userIsCalm = false;    // state: true = Calm, false = Resting
long    calmCandidateStart = 0;
long    restCandidateStart = 0;


// STRESSED MODE GLOBALS
boolean stressedActive = false;
long    stressedStartMs = 0;
int     stressedDurationMs = 60000;  // 60 seconds

int     stressedDeltaBpm = 1;        // ≥ resting + 5 bpm = stressed
int     stressedDwellMs  = 3000;     // hold 3 sec to switch

boolean userIsStressed   = false;    // stressed state flag
long    stressedCandStart = 0;       // timer for becoming stressed
long    deStressCandStart = 0;       // timer for returning to resting


//logic for stressed response buzzer TODO BROKEN
boolean prevUserIsStressed = false;


//functions for calm mode
void startCalm() {
  if (calmActive) return;
  playMP3("piano.mp3");
  calmStartMs = millis();
  calmActive = true;
  
  // capture resting from current reading if it's decent otherwise grab it in draw()
  int hr = graphGetHR();
  int conf = graphGetConf();
  restingHR = (conf >= calmMinConf && hr > 0) ? hr : 0;
  
  userIsCalm = false;
  calmCandidateStart = 0;
  restCandidateStart = 0;
}

//stops the music when we want 
void stopCalm() {
  calmActive = false;
  stopMP3();
}

//functions for stressed mode
void startStressed() {
  if (stressedActive) return;
  stressedActive   = true;
  stressedStartMs  = millis();
  userIsStressed   = false;
  stressedCandStart = 0;
  deStressCandStart = 0;

  // If restingHR not captured yet, try to snapshot from current reading
  int hr = graphGetHR();
  int conf = graphGetConf();
  if (restingHR == 0 && conf >= calmMinConf && hr > 0) {
    restingHR = hr;
  }
}

void stopStressed() {
  stressedActive = false;
}


void setup() {
  size(1000, 640);
  lpH = height - 20; 
  graphW = width - graphX - 10;
  graphH = height - graphY - 20;

  graphSetup();
  
  cp5.addButton("calmButton")
     .setLabel("Calm Mode")
     .setPosition(int(lpX+14), int(lpY+60))
     .setSize(220, 28);
  
  cp5.addButton("stopCalmButton")
     .setLabel("Stop Calm Mode")
     .setPosition(int(lpX+14), int(lpY+98))
     .setSize(220, 28);
     
  cp5.addButton("startStressedButton")
   .setLabel("Stressed (60s)")
   .setPosition(int(lpX+14), int(lpY+140))
   .setSize(220, 34);

  cp5.addButton("stopStressedButton")
   .setLabel("Stop Stressed")
   .setPosition(int(lpX+14), int(lpY+182))
   .setSize(220, 34);
     
 PFont btnFont = createFont("Arial", 8);
 cp5.getController("calmButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
 cp5.getController("stopCalmButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
 cp5.getController("startStressedButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
 cp5.getController("stopStressedButton").getCaptionLabel().setFont(btnFont).toUpperCase(false);
}

//per-button callbacks
void calmButton()      { startCalm(); }
void stopCalmButton()  { stopCalm();  }
void startStressedButton(){ startStressed(); }
void stopStressedButton(){  stopStressed();  }


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
  // Big HR and confidence displayed on the left side of the screen
  fill(240); textAlign(CENTER, CENTER); textSize(42); text(hr, cx, cy - 10);
  textSize(16); fill(180); text("Current bpm", cx, cy + 22);
  // Confidence
  textSize(14); fill(conf >= 80 ? 0xFFB4FFB4 : 0xFFE0C080);
  text("confidence: " + conf + "%", cx, cy + 44);
  popStyle(); //careful

  // right panel and graph size 
  noFill();
  stroke(90);


  // Original chart box inside graphDraw():
  int srcX = 50, srcY = 100;   // where it starts inside graphDraw()
  int srcW = 300, srcH = 200;  // chart size inside graphDraw()
  
  // Pick new chart size if needed
  int targetW = 400;
  int targetH = 300;
  
  // Scale factors to enlarge the chart
  float sx = targetW / (float)srcW;
  float sy = targetH / (float)srcH;
  
  // bounding box
  float bboxW = srcX * sx + targetW;
  float bboxH = srcY * sy + targetH;
  
  // center that bounding box inside the right panel
  pushMatrix();
  translate(graphX, graphY);
  float offX = (graphW - bboxW) * 0.5f;
  float offY = (graphH - bboxH) * 0.5f;
  translate(offX, offY);
  
  // Scale only the graph
  scale(sx, sy);
  graphDraw();
  popMatrix();
  
  pushMatrix(); 
  translate(graphX, graphY);
  
  popMatrix();
  
  
  //Calm detection logic
  // If restingHR wasn't captured at button press, grab the first good sample
  if (calmActive && restingHR == 0 && conf >= calmMinConf && hr > 0) {
    restingHR = hr;
  }

  if (calmActive && restingHR > 0 && conf >= calmMinConf) {
    long now = millis();

    if (!userIsCalm) {
      // Looking to become Calm: HR <= resting - delta for calmDwellMs
      if (hr <= restingHR - calmDeltaBpm) {
        if (calmCandidateStart == 0) calmCandidateStart = now;
        if (now - calmCandidateStart >= calmDwellMs) {
          userIsCalm = true;
          restCandidateStart = 0;
        }
      } else {
        calmCandidateStart = 0;
      }
    } else {
      // Currently Calm flip back to Resting if HR >= resting for calmDwellMs
      if (hr >= restingHR) {
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
    // Not active / no baseline / low confidence -> reset timers
    calmCandidateStart = 0;
    restCandidateStart = 0;
  }
  
 //stress detection logic
// If we still don't have a baseline and Stressed is running, grab first good sample
if (stressedActive && restingHR == 0 && conf >= calmMinConf && hr > 0) {
  
  restingHR = hr;
}

if (stressedActive && restingHR > 0 && conf >= calmMinConf) {
  long now = millis();

  if (!userIsStressed) {
    // Becoming stressed: HR >= resting + delta for stressedDwellMs
    if (hr >= restingHR + stressedDeltaBpm) {
      if (stressedCandStart == 0) stressedCandStart = now;
      if (now - stressedCandStart >= stressedDwellMs) {
        userIsStressed = true;
        deStressCandStart = 0;
      }
    } else {
      stressedCandStart = 0; // condition broke
    }
  } else {
    // Currently stressed flip back to resting if HR <= resting + 1 for dwell
    if (hr <= restingHR + 1) {
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

// TODO BROKEN
if (!prevUserIsStressed && userIsStressed) {
  try {
    myPort.write("BEEP2\n");   // sends the command to Arduino
  } catch (Exception ex) {
    println("Serial write failed: " + ex);
  }
}
//////////////////


prevUserIsStressed = userIsStressed;

// Auto-stop Stressed after 60 sec
if (stressedActive && (millis() - stressedStartMs >= stressedDurationMs)) {
  stopStressed();
}

//stressed mode overlay
if (stressedActive) {
  int remain = max(0, stressedDurationMs - int(millis() - stressedStartMs));
  float pad = 12, w = 220, h = 72;
  float x = graphX + pad, y = graphY + pad;
  pushStyle();
  noStroke(); fill(30, 200); rect(x, y, w, h, 10);
  fill(230); textAlign(CENTER, TOP); textSize(14);
  text("Stressed Mode", x+700, y+8);
  text("Time left: " + nf(remain/1000, 2) + "s", x+700, y+28);
  fill(userIsStressed ? color(255,120,120) : color(200));

  popStyle();
}
  
//User is: label on top-right of the GRAPH panel
String label;
color labelColor;

// Priority: Stressed, then Calm (if calm logic said calm), else Resting
if (userIsStressed) {
  label = "Stressed"; labelColor = color(255,120,120);
} else if (calmActive && /* your calm flag, e.g. */ userIsCalm) {
  label = "Calm";     labelColor = color(140,220,170);
} else {
  label = "Resting";  labelColor = color(210);
}

// draw the badge at top-right of graph panel
float pad = 12, w = 190, h = 54;
float bx = graphX + graphW - w - pad;
float by = graphY + pad;
pushStyle();
noStroke(); fill(30, 200); rect(bx, by, w, h, 10);
fill(200); textAlign(CENTER, TOP); textSize(14); text("User is:", bx + w/2, by + 6);
fill(labelColor); textAlign(CENTER, CENTER); textSize(20); text(label, bx + w/2, by + h/2 + 6);
popStyle();
  
}
  
