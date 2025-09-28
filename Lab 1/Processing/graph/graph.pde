import controlP5.*;
import processing.serial.*; 

ControlP5 cp5;
Serial myPort;
String inString;

class LineChart {
  int min = 20;
  int max = 120;
  IntList values;
  ArrayList<Integer> colors; // Use ArrayList<Integer> for better type safety
  LineChart(int size){
    values = new IntList(size);
    colors = new ArrayList<Integer>();
    for (int i=0; i < size; i++){
      values.append(60);
      colors.add(color(255));
    }
  }
  
  void draw(int x, int y, int width, int height){
    fill(0,0,0);
    stroke(0,0,0);
    rect(x,y,width,height);
    
    // Method 1: Draw actual points with individual colors
    drawPoints(x, y, width, height);
    
    // Method 2: Draw lines with gradient interpolation between points
    drawLinesWithGradient(x, y, width, height);
  }
  
  // Method 1: Draw visible points with their individual colors
  void drawPoints(int x, int y, int width, int height) {
    for (int i=0; i < values.size(); i++){
      float pointX = i * (width/float(values.size()-1)) + x;
      float pointY = (max-values.get(i)) * (height/float(max-min)) + y;
      
      fill(colors.get(i));
      noStroke();
      ellipse(pointX, pointY, 6, 6); // Draw circles for each point
    }
  }
  
  // Method 2: Draw lines with better color handling
  void drawLinesWithGradient(int x, int y, int width, int height) {
    for (int i=0; i < values.size()-1; i++){
      float leftPointX = i * (width/float(values.size()-1)) + x;
      float leftPointY = (max-values.get(i)) * (height/float(max-min)) + y;
      float rightPointX = (i+1) * (width/float(values.size()-1)) + x;
      float rightPointY = (max-values.get(i+1)) * (height/float(max-min)) + y;
      
      // Option A: Use left point color for line segment
      stroke(colors.get(i));
      line(leftPointX, leftPointY, rightPointX, rightPointY);
      
      // Option B: Could implement gradient between colors (more complex)
      // drawGradientLine(leftPointX, leftPointY, rightPointX, rightPointY, 
      //                 colors.get(i), colors.get(i+1));
    }
  }
  
  // Optional: Advanced gradient line drawing
  void drawGradientLine(float x1, float y1, float x2, float y2, color c1, color c2) {
    int steps = 20; // Number of segments for smooth gradient
    for (int i = 0; i < steps; i++) {
      float t = i / float(steps);
      float nextT = (i + 1) / float(steps);
      
      // Interpolate positions
      float currentX = lerp(x1, x2, t);
      float currentY = lerp(y1, y2, t);
      float nextX = lerp(x1, x2, nextT);
      float nextY = lerp(y1, y2, nextT);
      
      // Interpolate colors
      color currentColor = lerpColor(c1, c2, t);
      stroke(currentColor);
      line(currentX, currentY, nextX, nextY);
    }
  }
  
  void addShift(int v, color c){
    values.remove(0);
    values.append(v);
    colors.remove(0);
    colors.add(c);
  }
}

color RED = color(255,0,0);
color YELLOW = color(255,255,0);
color GREEN = color(0,255,0);
color BLUE = color(0,0,255);
color WHITE = color(255,255,255);

LineChart myChart;

// Function to get color based on heart rate value
color getHeartRateColor(int hr) {
  if (hr < 60) {
    return BLUE;        // Bradycardia (too slow)
  } else if (hr <= 80) {
    return GREEN;       // Normal range
  } else if (hr <= 100) {
    return YELLOW;      // Elevated but normal
  } else if (hr <= 120) {
    return color(255, 165, 0); // Orange - high
  } else {
    return RED;         // Tachycardia (too fast)
  }
}

// Alternative: Smooth color gradient based on HR
color getHeartRateGradient(int hr) {
  // Map HR to a color gradient from blue (low) to red (high)
  float normalizedHR = map(hr, 20, 120, 0, 1);
  normalizedHR = constrain(normalizedHR, 0, 1);
  
  if (normalizedHR < 0.5) {
    // Blue to Green (low to normal)
    return lerpColor(BLUE, GREEN, normalizedHR * 2);
  } else {
    // Green to Red (normal to high)
    return lerpColor(GREEN, RED, (normalizedHR - 0.5) * 2);
  }
}

void setup(){
  size(400,400);
  cp5 = new ControlP5(this);
  cp5.addTextfield("age")
    .setPosition(20,20)
    .setAutoClear(false)
    ;
  
  
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.clear();
  
  myChart = new LineChart(300);
}

void draw(){
   //Test mode: uncomment to see random heart rate data with colors
   if (frameCount % 30 == 0) { // Add new point every 30 frames (~0.5 seconds)
     int testHR = int(random(40, 130));
     myChart.addShift(testHR, getHeartRateGradient(testHR));
   }
  
  myChart.draw(50,100,300,200);
  
  // Display current heart rate color legend
  drawColorLegend();
}

void serialEvent(Serial p) { 
  String temp = p.readString();
  inString += temp;
  if (temp.equals("}")){
    //println(inString);
    
    JSONObject json = parseJSONObject(inString);
    if (json == null) {
      println("JSONObject could not be parsed");
    } else {
      println(json);
      int heartRate = json.getInt("HR");
      
      // Use intelligent color selection based on heart rate
      color pointColor = getHeartRateGradient(heartRate); // or use getHeartRateColor(heartRate)
      
      myChart.addShift(heartRate, pointColor);
    }
    // HR, Conf, Stat
    // Stat needs to be 3
    // Conf need to be not 0
    inString = "";
  }
  
  /*
  JSONObject json = parseJSONObject(inString);
  if (json == null) {
    println("JSONObject could not be parsed");
  } else {
    String species = json.getString("species");
    println(species);
  }
  */
}

// Draw a color legend showing what each color means
void drawColorLegend() {
  int legendX = 370;
  int legendY = 100;
  int legendWidth = 20;
  int legendHeight = 200;
  
  // Draw legend background
  fill(50);
  rect(legendX - 5, legendY - 5, legendWidth + 10, legendHeight + 30);
  
  // Draw color gradient
  for (int i = 0; i < legendHeight; i++) {
    float hr = map(i, 0, legendHeight, 120, 20); // Reverse mapping for visual
    color c = getHeartRateGradient(int(hr));
    stroke(c);
    line(legendX, legendY + i, legendX + legendWidth, legendY + i);
  }
  
  // Add labels
  fill(255);
  textAlign(RIGHT);
  text("120", legendX - 8, legendY + 5);
  text("100", legendX - 8, legendY + 50);
  text("80", legendX - 8, legendY + 100);
  text("60", legendX - 8, legendY + 150);
  text("20", legendX - 8, legendY + 200);
  
  textAlign(LEFT);
  text("BPM", legendX + legendWidth + 5, legendY + 100);
}
